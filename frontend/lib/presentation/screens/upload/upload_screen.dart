import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/route_names.dart';
import '../../providers/auth_provider.dart';
import '../../providers/book_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/romduol_button.dart';
import '../../widgets/common/romduol_text_field.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  int _step = 0;

  // Step 1 — Cover
  Uint8List? _coverBytes;
  String? _coverFileName;

  // Step 2 — Book file
  Uint8List? _bookBytes;
  String? _bookFileName;
  String? _fileType;
  String? _bookLink;

  // Step 3 — Metadata
  final _formKey = GlobalKey<FormState>();
  final _titleEn = TextEditingController();
  final _titleKm = TextEditingController();
  final _authorEn = TextEditingController();
  final _descEn = TextEditingController();
  final _descKm = TextEditingController();
  final _publisher = TextEditingController();
  final _year = TextEditingController();
  String _language = 'km';

  @override
  void dispose() {
    _titleEn.dispose();
    _titleKm.dispose();
    _authorEn.dispose();
    _descEn.dispose();
    _descKm.dispose();
    _publisher.dispose();
    _year.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text('upload_book'.tr())),
        body: Center(
          child: Text('login_required'.tr(), style: AppTextStyles.bodyLarge),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('upload_book'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () =>
              _step > 0 ? setState(() => _step--) : context.go(RouteNames.home),
        ),
      ),
      body: Column(
        children: [
          // Stepper indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Row(
              children: List.generate(4, (i) {
                final done = i < _step;
                final active = i == _step;
                return Expanded(
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done || active
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                        child: Center(
                          child: done
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : Text(
                                  '${i + 1}',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: active
                                        ? Colors.white
                                        : AppColors.textLight,
                                  ),
                                ),
                        ),
                      ),
                      if (i < 3)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: i < _step
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: IndexedStack(
              index: _step,
              children: [
                _CoverStep(
                  coverBytes: _coverBytes,
                  onPicked: (bytes, name) => setState(() {
                    _coverBytes = bytes;
                    _coverFileName = name;
                  }),
                  onNext: () => setState(() => _step = 1),
                ),
                _FileStep(
                  bookBytes: _bookBytes,
                  fileName: _bookFileName,
                  bookLink: _bookLink,
                  onPicked: (bytes, name, type) => setState(() {
                    _bookBytes = bytes;
                    _bookFileName = name;
                    _fileType = type;
                    _bookLink = null;
                  }),
                  onLinkChanged: (link) => setState(() {
                    _bookLink = link;
                    _bookBytes = null;
                    _bookFileName = null;
                    _fileType = null;
                  }),
                  onNext: () => setState(() => _step = 2),
                ),
                _MetadataStep(
                  formKey: _formKey,
                  titleEn: _titleEn,
                  titleKm: _titleKm,
                  authorEn: _authorEn,
                  descEn: _descEn,
                  descKm: _descKm,
                  publisher: _publisher,
                  year: _year,
                  language: _language,
                  onLanguageChanged: (l) => setState(() => _language = l),
                  onNext: () {
                    if (_formKey.currentState!.validate()) {
                      setState(() => _step = 3);
                    }
                  },
                ),
                _PreviewStep(
                  coverBytes: _coverBytes,
                  title:
                      _titleKm.text.isNotEmpty ? _titleKm.text : _titleEn.text,
                  author: _authorEn.text,
                  fileType: _fileType ?? (_bookLink != null ? 'link' : 'pdf'),
                  onSubmit: _onSubmit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSubmit() async {
    final repo = ref.read(bookRepositoryProvider);
    final progress = ref.read(uploadProgressProvider.notifier);

    final result = await repo.uploadBook(
      titleEn: _titleEn.text,
      titleKm: _titleKm.text.isNotEmpty ? _titleKm.text : null,
      author: _authorEn.text,
      description: _descEn.text.isNotEmpty ? _descEn.text : null,
      descriptionKm: _descKm.text.isNotEmpty ? _descKm.text : null,
      publisher: _publisher.text.isNotEmpty ? _publisher.text : null,
      publishYear: int.tryParse(_year.text.trim()),
      language: _language,
      coverBytes: _coverBytes,
      coverFileName: _coverFileName,
      bookBytes: _bookBytes,
      bookFileName: _bookFileName ?? 'book',
      bookLink: _bookLink,
      onProgress: (p) => progress.state = p,
    );

    result.fold(
      (err) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      ),
      (book) {
        final msg = book.status == 'approved'
            ? 'upload_success_approved'.tr()
            : 'upload_success'.tr();
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
        if (mounted) context.go(RouteNames.home);
      },
    );
  }
}

class _CoverStep extends StatelessWidget {
  final Uint8List? coverBytes;
  final void Function(Uint8List bytes, String name) onPicked;
  final VoidCallback onNext;

  const _CoverStep({
    required this.coverBytes,
    required this.onPicked,
    required this.onNext,
  });

  Future<void> _pick(BuildContext context) async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 1200,
    );
    if (img != null) {
      final bytes = await img.readAsBytes();
      onPicked(bytes, img.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _pick(context),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: coverBytes != null
                        ? AppColors.primary
                        : AppColors.border,
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                ),
                child: coverBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(coverBytes!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 64,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'tap_to_pick_cover'.tr(),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          RomduolButton(
            label: 'next'.tr(),
            onPressed: coverBytes != null ? onNext : null,
          ),
        ],
      ),
    );
  }
}

class _FileStep extends StatefulWidget {
  final Uint8List? bookBytes;
  final String? fileName;
  final String? bookLink;
  final void Function(Uint8List, String, String) onPicked;
  final void Function(String) onLinkChanged;
  final VoidCallback onNext;

  const _FileStep({
    required this.bookBytes,
    required this.fileName,
    required this.bookLink,
    required this.onPicked,
    required this.onLinkChanged,
    required this.onNext,
  });

  @override
  State<_FileStep> createState() => _FileStepState();
}

class _FileStepState extends State<_FileStep> {
  bool _useLink = false;
  late final TextEditingController _linkController;

  @override
  void initState() {
    super.initState();
    _useLink = widget.bookLink != null && widget.bookLink!.isNotEmpty;
    _linkController = TextEditingController(text: widget.bookLink ?? '');
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'epub', 'docx'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      final file = result.files.single;
      final ext = file.name.split('.').last.toLowerCase();
      widget.onPicked(file.bytes!, file.name, ext);
    }
  }

  bool get _isLinkValid {
    final link = _linkController.text.trim();
    if (link.isEmpty) return false;
    final uri = Uri.tryParse(link);
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }

  bool get _canProceed => _useLink ? _isLinkValid : widget.bookBytes != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Toggle between file upload and link
          Row(
            children: [
              Expanded(
                child: _OptionChip(
                  icon: Icons.upload_file_rounded,
                  label: 'upload_file'.tr(),
                  selected: !_useLink,
                  onTap: () => setState(() => _useLink = false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OptionChip(
                  icon: Icons.link_rounded,
                  label: 'paste_link'.tr(),
                  selected: _useLink,
                  onTap: () => setState(() => _useLink = true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _useLink ? _buildLinkInput() : _buildFilePicker(),
          ),
          const SizedBox(height: 24),
          RomduolButton(
            label: 'next'.tr(),
            onPressed: _canProceed ? widget.onNext : null,
          ),
        ],
      ),
    );
  }

  Widget _buildFilePicker() {
    return GestureDetector(
      onTap: _pick,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                widget.bookBytes != null ? AppColors.primary : AppColors.border,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.bookBytes != null
                  ? Icons.insert_drive_file_rounded
                  : Icons.upload_file_rounded,
              size: 72,
              color: widget.bookBytes != null
                  ? AppColors.primary
                  : AppColors.textLight,
            ),
            const SizedBox(height: 8),
            Text(
              widget.fileName ?? 'tap_to_pick_file'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: widget.bookBytes != null
                    ? AppColors.textDark
                    : AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'supported_formats'.tr(),
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkInput() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isLinkValid ? AppColors.primary : AppColors.border,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isLinkValid ? Icons.check_circle_rounded : Icons.link_rounded,
              size: 56,
              color: _isLinkValid ? AppColors.primary : AppColors.textLight,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _linkController,
              decoration: InputDecoration(
                hintText: 'paste_link_hint'.tr(),
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textLight,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
                prefixIcon: const Icon(Icons.link, color: AppColors.textLight),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              keyboardType: TextInputType.url,
              onChanged: (value) {
                setState(() {});
                if (_isLinkValid) {
                  widget.onLinkChanged(value.trim());
                }
              },
            ),
            const SizedBox(height: 8),
            Text(
              'link_supported_sources'.tr(),
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 20,
                color: selected ? AppColors.primary : AppColors.textLight),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: selected ? AppColors.primary : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetadataStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleEn;
  final TextEditingController titleKm;
  final TextEditingController authorEn;
  final TextEditingController descEn;
  final TextEditingController descKm;
  final TextEditingController publisher;
  final TextEditingController year;
  final String language;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onNext;

  const _MetadataStep({
    required this.formKey,
    required this.titleEn,
    required this.titleKm,
    required this.authorEn,
    required this.descEn,
    required this.descKm,
    required this.publisher,
    required this.year,
    required this.language,
    required this.onLanguageChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RomduolTextField(
              controller: titleEn,
              labelText: 'title_en'.tr(),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'required'.tr() : null,
            ),
            RomduolTextField(controller: titleKm, labelText: 'title_km'.tr()),
            RomduolTextField(
              controller: authorEn,
              labelText: 'author'.tr(),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'required'.tr() : null,
            ),
            Text('book_language'.tr(), style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'km', label: Text('lang_km'.tr())),
                ButtonSegment(value: 'en', label: Text('lang_en'.tr())),
                ButtonSegment(value: 'fr', label: Text('lang_fr'.tr())),
              ],
              selected: {language},
              onSelectionChanged: (s) => onLanguageChanged(s.first),
            ),
            const SizedBox(height: 16),
            RomduolTextField(
              controller: descEn,
              labelText: 'description_en'.tr(),
              maxLines: 4,
            ),
            RomduolTextField(
              controller: descKm,
              labelText: 'description_km'.tr(),
              maxLines: 4,
            ),
            Row(
              children: [
                Expanded(
                  child: RomduolTextField(
                    controller: publisher,
                    labelText: 'publisher'.tr(),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: RomduolTextField(
                    controller: year,
                    labelText: 'year'.tr(),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            RomduolButton(label: 'next'.tr(), onPressed: onNext),
          ],
        ),
      ),
    );
  }
}

class _PreviewStep extends ConsumerWidget {
  final Uint8List? coverBytes;
  final String title;
  final String author;
  final String fileType;
  final AsyncCallback onSubmit;

  const _PreviewStep({
    required this.coverBytes,
    required this.title,
    required this.author,
    required this.fileType,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(uploadProgressProvider);
    final isUploading = progress > 0 && progress < 1.0;
    final requireApproval =
        ref.watch(requireBookApprovalProvider).valueOrNull ?? true;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (coverBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:
                    Image.memory(coverBytes!, height: 200, fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.headlineMedium),
            const SizedBox(height: 4),
            Text(author, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 4),
            Text(fileType.toUpperCase(), style: AppTextStyles.caption),
            const SizedBox(height: 24),
            if (isUploading) ...[
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 8),
              Text('${(progress * 100).round()}%',
                  style: AppTextStyles.caption),
              const SizedBox(height: 16),
            ],
            Text(
              requireApproval
                  ? 'pending_review_note'.tr()
                  : 'auto_approved_note'.tr(),
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
            ),
            const SizedBox(height: 16),
            RomduolButton(
              label: requireApproval
                  ? 'submit_for_review'.tr()
                  : 'submit_book'.tr(),
              onPressed: isUploading ? null : onSubmit,
              isLoading: isUploading,
            ),
          ],
        ),
      ),
    );
  }
}
