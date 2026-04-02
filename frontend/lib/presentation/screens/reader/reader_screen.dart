import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart' as dio;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../providers/book_provider.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/lotus_loader.dart';
import '../../widgets/common/romduol_button.dart';

// Web: reader_web.dart (dart:html iframe); Native: reader_stub.dart (no-op)
import 'reader_stub.dart' if (dart.library.html) 'reader_web.dart' as platform;

class ReaderScreen extends ConsumerWidget {
  final String bookId;
  const ReaderScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(bookDetailProvider(bookId));

    return bookAsync.when(
      loading: () =>
          const Scaffold(backgroundColor: Colors.black, body: LotusLoader()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(message: e.toString()),
      ),
      data: (book) {
        if (book.fileUrl.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(book.title)),
            body: ErrorView(message: 'no_file'.tr()),
          );
        }
        // Link-type books: open the external URL directly
        if (book.isLink) {
          return _ExternalLinkScaffold(
            title: book.titleKm ?? book.title,
            fileUrl: book.fileUrl,
          );
        }
        // Web: SfPdfViewer.memory uses DDC Uint8List which Syncfusion's JS
        // renderer can't handle in debug mode. Use pdf_viewer.html (PDF.js)
        // which receives base64 JSON and renders entirely in browser JS.
        if (kIsWeb) {
          return _WebReaderScaffold(
            title: book.titleKm ?? book.title,
            fileUrl: book.fileUrl,
          );
        }
        // Native (Android / iOS): fetch base64 JSON, decode, render with
        // SfPdfViewer — high quality vector rendering + pinch / double-tap zoom.
        return _NativeReaderScaffold(
          title: book.titleKm ?? book.title,
          fileUrl: book.fileUrl,
        );
      },
    );
  }
}

// ── External link reader ─────────────────────────────────────────────────────

class _ExternalLinkScaffold extends StatefulWidget {
  final String title;
  final String fileUrl;
  const _ExternalLinkScaffold({required this.title, required this.fileUrl});

  @override
  State<_ExternalLinkScaffold> createState() => _ExternalLinkScaffoldState();
}

class _ExternalLinkScaffoldState extends State<_ExternalLinkScaffold> {
  @override
  void initState() {
    super.initState();
    _openLink();
  }

  Future<void> _openLink() async {
    final uri = Uri.tryParse(widget.fileUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.title,
          style: AppTextStyles.titleMedium,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.link_rounded,
                  size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'external_link_book'.tr(),
                style: AppTextStyles.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.fileUrl,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textLight),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              RomduolButton(
                label: 'open_link'.tr(),
                icon: Icons.open_in_new_rounded,
                onPressed: _openLink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Web reader ───────────────────────────────────────────────────────────────

class _WebReaderScaffold extends StatefulWidget {
  final String title;
  final String fileUrl;
  const _WebReaderScaffold({required this.title, required this.fileUrl});

  @override
  State<_WebReaderScaffold> createState() => _WebReaderScaffoldState();
}

class _WebReaderScaffoldState extends State<_WebReaderScaffold> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'pdf-viewer-${widget.fileUrl.hashCode}';
    platform.registerPdfView(_viewType, widget.fileUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.6),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.title,
          style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SizedBox.expand(
        child: HtmlElementView(viewType: _viewType),
      ),
    );
  }
}

// ── Native reader ────────────────────────────────────────────────────────────

class _NativeReaderScaffold extends StatefulWidget {
  final String title;
  final String fileUrl;
  const _NativeReaderScaffold({required this.title, required this.fileUrl});

  @override
  State<_NativeReaderScaffold> createState() => _NativeReaderScaffoldState();
}

class _NativeReaderScaffoldState extends State<_NativeReaderScaffold> {
  Uint8List? _pdfBytes;
  bool _isLoading = true;
  String? _error;
  final PdfViewerController _controller = PdfViewerController();
  bool _showBars = true;
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  /// The /read endpoint returns {"type":…,"data":"<base64>"} (application/json).
  /// IDM and download managers ignore JSON — no download dialog on mobile either.
  Future<void> _loadPdf() async {
    try {
      final client = dio.Dio();
      final response = await client.get<Map<String, dynamic>>(widget.fileUrl);
      final base64Data = response.data!['data'] as String;
      final bytes = base64Decode(base64Data);
      if (!mounted) return;
      setState(() {
        _pdfBytes = bytes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => setState(() => _showBars = !_showBars),
        child: Stack(
          children: [
            // ── PDF content ────────────────────────────────────────────
            if (_isLoading)
              const Center(child: LotusLoader())
            else if (_error != null)
              Center(child: ErrorView(message: _error!))
            else
              SfPdfViewer.memory(
                _pdfBytes!,
                controller: _controller,
                enableDoubleTapZooming: true,
                pageLayoutMode: PdfPageLayoutMode.continuous,
                scrollDirection: PdfScrollDirection.vertical,
                onDocumentLoaded: (details) {
                  setState(() => _totalPages = details.document.pages.count);
                },
                onPageChanged: (details) {
                  setState(() => _currentPage = details.newPageNumber);
                },
                onDocumentLoadFailed: (details) {
                  setState(() => _error = details.description);
                },
              ),

            // ── Top app bar ────────────────────────────────────────────
            AnimatedSlide(
              duration: const Duration(milliseconds: 200),
              offset: _showBars ? Offset.zero : const Offset(0, -1),
              child: SafeArea(
                child: Material(
                  color: Colors.black.withOpacity(0.6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () => context.pop(),
                        ),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: AppTextStyles.titleMedium
                                .copyWith(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Bottom page bar ────────────────────────────────────────
            if (_totalPages > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 200),
                  offset: _showBars ? Offset.zero : const Offset(0, 1),
                  child: SafeArea(
                    child: Material(
                      color: Colors.black.withOpacity(0.6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.chevron_left,
                                color: Colors.white,
                              ),
                              onPressed: _currentPage > 1
                                  ? () => _controller.previousPage()
                                  : null,
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 2,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 8,
                                  ),
                                ),
                                child: Slider(
                                  value: _currentPage.toDouble(),
                                  min: 1,
                                  max: _totalPages.toDouble(),
                                  activeColor: AppColors.primary,
                                  inactiveColor: AppColors.border,
                                  onChanged: (v) =>
                                      _controller.jumpToPage(v.round()),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.chevron_right,
                                color: Colors.white,
                              ),
                              onPressed: _currentPage < _totalPages
                                  ? () => _controller.nextPage()
                                  : null,
                            ),
                            Text(
                              '$_currentPage / $_totalPages',
                              style: AppTextStyles.caption
                                  .copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
