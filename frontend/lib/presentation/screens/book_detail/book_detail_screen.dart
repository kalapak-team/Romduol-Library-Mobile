import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/route_names.dart';
import '../../../core/utils/download_helper.dart';
import '../../../data/models/book_model.dart';
import '../../../data/models/review_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/book_provider.dart';
import '../../widgets/book/book_badge.dart';
import '../../widgets/book/book_thumbnail.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/lotus_loader.dart';
import '../../widgets/common/romduol_button.dart';

class BookDetailScreen extends ConsumerStatefulWidget {
  final String bookId;
  const BookDetailScreen({super.key, required this.bookId});

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _showKhmer = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(bookDetailProvider(widget.bookId));
    return bookAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: LotusLoader(),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(),
        body: ErrorView(message: e.toString()),
      ),
      data: (book) => _BookDetailBody(
        book: book,
        showKhmer: _showKhmer,
        tabs: _tabs,
        onToggleLanguage: () => setState(() => _showKhmer = !_showKhmer),
      ),
    );
  }
}

class _BookDetailBody extends ConsumerStatefulWidget {
  final BookModel book;
  final bool showKhmer;
  final TabController tabs;
  final VoidCallback onToggleLanguage;

  const _BookDetailBody({
    required this.book,
    required this.showKhmer,
    required this.tabs,
    required this.onToggleLanguage,
  });

  @override
  ConsumerState<_BookDetailBody> createState() => _BookDetailBodyState();
}

enum _DLStatus { idle, downloading, done }

class _BookDetailBodyState extends ConsumerState<_BookDetailBody> {
  bool _isFavorited = false;
  _DLStatus _dlStatus = _DLStatus.idle;

  String _formatViewsAndDate(BookModel book) {
    final views = NumberFormat.decimalPattern().format(book.viewCount);
    final date = DateTime.tryParse(book.createdAt)?.toLocal();
    if (date == null) return '$views ${'views'.tr()}';
    return '$views ${'views'.tr()} ${DateFormat('MMM d, yyyy').format(date)}';
  }

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.book.isFavorited ?? false;
  }

  @override
  void didUpdateWidget(covariant _BookDetailBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book.id != widget.book.id) {
      _isFavorited = widget.book.isFavorited ?? false;
    }
  }

  Future<void> _refreshBooks() async {
    ref.invalidate(bookDetailProvider(widget.book.id));
    ref.invalidate(bookReviewsProvider(widget.book.id));
    await ref.read(bookDetailProvider(widget.book.id).future);
  }

  void _handleAction(BuildContext context, String action, BookModel book) {
    switch (action) {
      case 'edit':
        _showEditSheet(context, book);
      case 'visibility':
        _toggleVisibility(context, book);
      case 'delete':
        _confirmDelete(context, book);
    }
  }

  void _showEditSheet(BuildContext context, BookModel book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _BookDetailEditSheet(
        book: book,
        onSave: (data) async {
          final repo = ref.read(bookRepositoryProvider);
          final result = await repo.updateBook(
            bookId: book.id,
            title: data['title'] as String?,
            titleKm: data['title_km'] as String?,
            description: data['description'] as String?,
            descriptionKm: data['description_km'] as String?,
            publishYear: data['publication_year'] as int?,
            isPrivate: data['is_private'] as bool?,
          );
          result.fold(
            (err) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(err),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            (_) {
              ref.invalidate(bookDetailProvider(book.id));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Book updated.'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
          );
        },
      ),
    );
  }

  Future<void> _toggleVisibility(BuildContext context, BookModel book) async {
    final repo = ref.read(bookRepositoryProvider);
    final result = await repo.updateBook(
      bookId: book.id,
      isPrivate: !book.isPrivate,
    );
    result.fold(
      (err) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(err),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      (_) {
        ref.invalidate(bookDetailProvider(book.id));
        if (context.mounted) {
          final msg = book.isPrivate ? 'Set to Public.' : 'Set to Private.';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
    );
  }

  void _confirmDelete(BuildContext context, BookModel book) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text(
            'Delete \u201c${book.titleKm ?? book.title}\u201d? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final repo = ref.read(bookRepositoryProvider);
              final result = await repo.deleteBook(book.id);
              result.fold(
                (err) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(err),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                },
                (_) {
                  if (context.mounted) {
                    ref.invalidate(featuredBooksProvider);
                    ref.invalidate(catalogBooksProvider);
                    context.pop();
                  }
                },
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final currentUser = ref.watch(authStateProvider).valueOrNull;
    final isOwner = currentUser != null && currentUser.id == book.userId;
    final isAdmin = currentUser?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DefaultTabController(
        length: 2,
        child: RefreshIndicator(
          onRefresh: _refreshBooks,
          color: AppColors.primary,
          child: NestedScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            headerSliverBuilder: (_, __) => [
              SliverAppBar(
                expandedHeight: 340,
                pinned: true,
                backgroundColor: AppColors.background,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      _isFavorited
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: _isFavorited ? AppColors.primary : null,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_rounded),
                    onPressed: _shareBook,
                  ),
                  if (isOwner || isAdmin)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded),
                      onSelected: (val) => _handleAction(context, val, book),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit_outlined),
                              title: Text('Edit'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            )),
                        PopupMenuItem(
                            value: 'visibility',
                            child: ListTile(
                              leading: Icon(book.isPrivate
                                  ? Icons.public_rounded
                                  : Icons.lock_outline_rounded),
                              title: Text(book.isPrivate
                                  ? 'Set to Public'
                                  : 'Set to Private'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            )),
                        const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete_outline_rounded,
                                  color: AppColors.error),
                              title: Text('Delete',
                                  style: TextStyle(color: AppColors.error)),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            )),
                      ],
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Blurred background cover
                      (book.coverUrl != null &&
                              book.coverUrl!.trim().isNotEmpty)
                          ? Image.network(
                              book.coverUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                  color: AppColors.primaryWithOpacity12),
                            )
                          : Container(color: AppColors.primaryWithOpacity12),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, AppColors.background],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.4, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 24,
                        left: 24,
                        right: 24,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Book cover
                            Hero(
                              tag: 'book_cover_${book.id}',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: BookThumbnail(
                                  book: book,
                                  width: 90,
                                  height: 130,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (book.titleKm != null)
                                    GestureDetector(
                                      onTap: widget.onToggleLanguage,
                                      child: Text(
                                        widget.showKhmer
                                            ? (book.titleKm ?? book.title)
                                            : book.title,
                                        style: AppTextStyles.headlineMedium
                                            .copyWith(
                                                color: AppColors.textDark),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  else
                                    Text(
                                      book.title,
                                      style: AppTextStyles.headlineMedium
                                          .copyWith(color: AppColors.textDark),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    book.author,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textMid,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatViewsAndDate(book),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textMid,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      BookBadge(
                                        type: book.isFeatured
                                            ? BookBadgeType.featured
                                            : BookBadgeType.approved,
                                      ),
                                      const SizedBox(width: 6),
                                      BookBadge(
                                        type: book.language == 'km'
                                            ? BookBadgeType.khmer
                                            : BookBadgeType.newBook,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Stats row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Stat(
                        icon: Icons.star_rounded,
                        value: book.avgRating.toStringAsFixed(1),
                        label: 'rating'.tr(),
                      ),
                      _Divider(),
                      _Stat(
                        icon: Icons.download_outlined,
                        value: book.downloadCount.toString(),
                        label: 'downloads'.tr(),
                      ),
                      _Divider(),
                      _Stat(
                        icon: Icons.rate_review_outlined,
                        value: book.reviewCount.toString(),
                        label: 'reviews'.tr(),
                      ),
                      _Divider(),
                      _Stat(
                        icon: Icons.description_outlined,
                        value: book.fileType.toUpperCase(),
                        label: 'format'.tr(),
                      ),
                    ],
                  ),
                ),
              ),
              // Action buttons
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: RomduolButton(
                          label: 'read_now'.tr(),
                          onPressed: () =>
                              context.push(RouteNames.readerPath(book.id)),
                          icon: Icons.auto_stories_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: _DownloadButton(
                          status: _dlStatus,
                          onPressed: _onDownload,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              // Tab bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
                  TabBar(
                    controller: widget.tabs,
                    tabs: [
                      Tab(text: 'about'.tr()),
                      Tab(text: 'reviews'.tr()),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: widget.tabs,
              children: [
                _AboutTab(book: book, showKhmer: widget.showKhmer),
                _ReviewsTab(bookId: book.id),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isFavorited = !_isFavorited);
    final repo = ref.read(bookRepositoryProvider);
    final result = await repo.toggleFavorite(widget.book.id);
    result.fold(
      (error) {
        if (mounted) {
          setState(() => _isFavorited = !_isFavorited);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      },
      (isFav) {
        if (mounted) {
          setState(() => _isFavorited = isFav);
        }
      },
    );
  }

  void _shareBook() {
    final book = widget.book;
    final bookUrl = '${ApiEndpoints.baseUrl}/books/${book.id}';
    final shareText = '${book.title} - ${book.author}\n$bookUrl';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text('share'.tr(), style: AppTextStyles.headlineSmall),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ShareOption(
                    icon: Icons.copy_rounded,
                    label: 'copy_link'.tr(),
                    color: AppColors.textDark,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: bookUrl));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('link_copied'.tr())),
                      );
                    },
                  ),
                  _ShareOption(
                    icon: Icons.telegram,
                    label: 'Telegram',
                    color: const Color(0xFF0088CC),
                    onTap: () {
                      Navigator.pop(context);
                      launchUrl(
                        Uri.parse(
                            'https://t.me/share/url?url=${Uri.encodeComponent(bookUrl)}&text=${Uri.encodeComponent('${book.title} - ${book.author}')}'),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),
                  _ShareOption(
                    icon: Icons.facebook_rounded,
                    label: 'Facebook',
                    color: const Color(0xFF1877F2),
                    onTap: () {
                      Navigator.pop(context);
                      launchUrl(
                        Uri.parse(
                            'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(bookUrl)}'),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),
                  _ShareOption(
                    icon: Icons.close,
                    label: 'X',
                    color: Colors.black,
                    onTap: () {
                      Navigator.pop(context);
                      launchUrl(
                        Uri.parse(
                            'https://twitter.com/intent/tweet?url=${Uri.encodeComponent(bookUrl)}&text=${Uri.encodeComponent('${book.title} - ${book.author}')}'),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Share.share(shareText);
                  },
                  icon: const Icon(Icons.share_rounded),
                  label: Text('more_options'.tr()),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onDownload() async {
    // For link-type books, open the external URL directly
    if (widget.book.isLink) {
      final uri = Uri.tryParse(widget.book.fileUrl);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }
    if (!mounted) return;
    setState(() => _dlStatus = _DLStatus.downloading);
    try {
      await downloadBook(widget.book.id, widget.book.title);
      if (!mounted) return;
      setState(() => _dlStatus = _DLStatus.done);
      await Future.delayed(const Duration(milliseconds: 2000));
      if (!mounted) return;
      setState(() => _dlStatus = _DLStatus.idle);
    } catch (e) {
      if (!mounted) return;
      setState(() => _dlStatus = _DLStatus.idle);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }
}

// ── Google-Play-style download button ───────────────────────────────────────

class _DownloadButton extends StatelessWidget {
  final _DLStatus status;
  final VoidCallback? onPressed;

  const _DownloadButton({required this.status, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDone = status == _DLStatus.done;
    final isLoading = status == _DLStatus.downloading;

    final borderColor = isDone ? const Color(0xFF34A853) : primary;
    final bgColor = isDone ? const Color(0xFF34A853) : Colors.transparent;

    return SizedBox(
      height: 52,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: (!isLoading && !isDone) ? onPressed : null,
            borderRadius: BorderRadius.circular(8),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: isDone
                    ? const Icon(
                        Icons.check_rounded,
                        key: ValueKey('done'),
                        color: Colors.white,
                        size: 24,
                      )
                    : isLoading
                        ? SizedBox(
                            key: const ValueKey('loading'),
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: primary,
                            ),
                          )
                        : Icon(
                            Icons.download_rounded,
                            key: const ValueKey('idle'),
                            color: primary,
                            size: 22,
                          ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _Stat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppColors.border);
  }
}

class _AboutTab extends StatelessWidget {
  final BookModel book;
  final bool showKhmer;

  const _AboutTab({required this.book, required this.showKhmer});

  String _formatPostedDate(String createdAt) {
    final date = DateTime.tryParse(createdAt)?.toLocal();
    if (date == null) return '—';
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Uploader card
        if (book.uploader != null) _UploaderCard(uploader: book.uploader!),
        if (book.uploader != null) const SizedBox(height: 12),
        _InfoRow(label: 'author'.tr(), value: book.author),
        if (book.isbn != null) _InfoRow(label: 'ISBN', value: book.isbn!),
        _InfoRow(
            label: 'year'.tr(), value: book.publishYear?.toString() ?? '—'),
        if (book.publisher != null)
          _InfoRow(label: 'publisher'.tr(), value: book.publisher!),
        if (book.category != null)
          _InfoRow(
            label: 'category'.tr(),
            value: showKhmer && book.category!.nameKm != null
                ? book.category!.nameKm!
                : book.category!.name,
          ),
        const Divider(height: 24),
        Text('description'.tr(), style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        Text(
          showKhmer
              ? (book.descriptionKm ?? book.description ?? '')
              : (book.description ?? ''),
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textLight,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}

class _ReviewsTab extends ConsumerStatefulWidget {
  final String bookId;
  const _ReviewsTab({required this.bookId});

  @override
  ConsumerState<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends ConsumerState<_ReviewsTab> {
  final _reviewController = TextEditingController();
  double _myRating = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_myRating == 0) return;
    setState(() => _submitting = true);
    final repo = ref.read(bookRepositoryProvider);
    await repo.addReview(
      bookId: widget.bookId,
      rating: _myRating.round(),
      body: _reviewController.text,
    );
    ref.invalidate(bookReviewsProvider(widget.bookId));
    _reviewController.clear();
    setState(() {
      _myRating = 0;
      _submitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(bookReviewsProvider(widget.bookId));
    final user = ref.watch(authStateProvider).valueOrNull;
    final reviewHintText = context.locale.languageCode == 'km'
        ? 'សូមសរសេរមតិយោបល់អំពីសៀវភៅនេះ...'
        : 'Share your thoughts about this book...';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (user != null) ...[
          Text('write_review'.tr(), style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              for (int i = 1; i <= 5; i++)
                GestureDetector(
                  onTap: () => setState(() => _myRating = i.toDouble()),
                  child: Icon(
                    i <= _myRating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: AppColors.accent,
                    size: 32,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reviewController,
            maxLines: 3,
            decoration: InputDecoration(hintText: reviewHintText),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('submit'.tr()),
            ),
          ),
          const Divider(height: 24),
        ],
        reviewsAsync.when(
          loading: () => const InlineLoader(),
          error: (e, _) => ErrorView(message: e.toString()),
          data: (reviews) => reviews.isEmpty
              ? Center(
                  child: Text(
                    'no_reviews'.tr(),
                    style: AppTextStyles.bodyMedium,
                  ),
                )
              : Column(
                  children: reviews.map((r) => _ReviewCard(review: r)).toList(),
                ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final hasAvatar = review.user?.avatarUrl != null &&
        review.user!.avatarUrl!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(
          BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryWithOpacity12,
                backgroundImage:
                    hasAvatar ? NetworkImage(review.user!.avatarUrl!) : null,
                child: !hasAvatar
                    ? Text(
                        review.user?.name.characters.first ?? '?',
                        style: AppTextStyles.labelLarge,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.user?.nameKm ?? review.user?.name ?? 'Anonymous',
                      style: AppTextStyles.labelMedium,
                    ),
                    Text(
                      DateFormat(
                        'MMM d, y',
                      ).format(DateTime.tryParse(review.createdAt) ??
                          DateTime.now()),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 14,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          if (review.body != null) ...[
            const SizedBox(height: 8),
            Text(review.body!, style: AppTextStyles.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _UploaderCard extends StatelessWidget {
  final BookUploaderInfo uploader;
  const _UploaderCard({required this.uploader});

  @override
  Widget build(BuildContext context) {
    final hasAvatar =
        uploader.avatarUrl != null && uploader.avatarUrl!.trim().isNotEmpty;
    final displayName = uploader.nameKm ?? uploader.name;

    return GestureDetector(
      onTap: () => context.push(RouteNames.userProfilePath(uploader.username)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: const Border.fromBorderSide(
            BorderSide(color: AppColors.border),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primaryWithOpacity12,
              backgroundImage:
                  hasAvatar ? NetworkImage(uploader.avatarUrl!) : null,
              child: !hasAvatar
                  ? Text(
                      displayName.isNotEmpty
                          ? displayName.substring(0, 1).toUpperCase()
                          : '?',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'uploaded_by'.tr(),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayName,
                    style: AppTextStyles.labelMedium,
                  ),
                  Text(
                    '@${uploader.username}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMid,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _StickyTabBarDelegate(this.tabBar);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: AppColors.background, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Edit book sheet (book detail) ────────────────────────────────────────────

class _BookDetailEditSheet extends StatefulWidget {
  final BookModel book;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _BookDetailEditSheet({required this.book, required this.onSave});

  @override
  State<_BookDetailEditSheet> createState() => _BookDetailEditSheetState();
}

class _BookDetailEditSheetState extends State<_BookDetailEditSheet> {
  late final TextEditingController _titleEn;
  late final TextEditingController _titleKm;
  late final TextEditingController _descEn;
  late final TextEditingController _descKm;
  late final TextEditingController _publishYear;
  late bool _isPrivate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleEn = TextEditingController(text: widget.book.title);
    _titleKm = TextEditingController(text: widget.book.titleKm ?? '');
    _descEn = TextEditingController(text: widget.book.description ?? '');
    _descKm = TextEditingController(text: widget.book.descriptionKm ?? '');
    _publishYear =
        TextEditingController(text: widget.book.publishYear?.toString() ?? '');
    _isPrivate = widget.book.isPrivate;
  }

  @override
  void dispose() {
    _titleEn.dispose();
    _titleKm.dispose();
    _descEn.dispose();
    _descKm.dispose();
    _publishYear.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('Edit Book', style: AppTextStyles.titleMedium),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 12),
            _field('Title (English)', _titleEn),
            const SizedBox(height: 10),
            _field('Title (Khmer)', _titleKm),
            const SizedBox(height: 10),
            _field('Description (English)', _descEn, maxLines: 3),
            const SizedBox(height: 10),
            _field('Description (Khmer)', _descKm, maxLines: 3),
            const SizedBox(height: 10),
            _field('Year Published', _publishYear,
                keyboardType: TextInputType.number),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(children: [
                _VisibilityOption(
                  icon: Icons.public_rounded,
                  title: 'Public',
                  subtitle: 'Everyone can see this book',
                  selected: !_isPrivate,
                  onTap: () => setState(() => _isPrivate = false),
                ),
                const Divider(height: 1),
                _VisibilityOption(
                  icon: Icons.lock_outline_rounded,
                  title: 'Only me',
                  subtitle: 'Only you can see this book',
                  selected: _isPrivate,
                  onTap: () => setState(() => _isPrivate = true),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Save', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelMedium),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSave({
      'title': _titleEn.text.trim(),
      'title_km': _titleKm.text.trim().isEmpty ? null : _titleKm.text.trim(),
      'description': _descEn.text.trim().isEmpty ? null : _descEn.text.trim(),
      'description_km':
          _descKm.text.trim().isEmpty ? null : _descKm.text.trim(),
      'publication_year': int.tryParse(_publishYear.text.trim()),
      'is_private': _isPrivate,
    });
    if (mounted) Navigator.pop(context);
    setState(() => _saving = false);
  }
}

class _VisibilityOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _VisibilityOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading:
          Icon(icon, color: selected ? AppColors.primary : AppColors.textLight),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          color: selected ? AppColors.primary : null,
        ),
      ),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : null,
    );
  }
}
