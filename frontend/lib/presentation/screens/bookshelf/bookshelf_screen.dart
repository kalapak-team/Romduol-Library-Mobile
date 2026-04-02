import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/route_names.dart';
import '../../../data/models/book_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/book_provider.dart';
import '../../widgets/book/book_thumbnail.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/lotus_loader.dart';

// ─── Providers ───────────────────────────────────────────────────────────────

final favoriteBooksProvider = FutureProvider.autoDispose<List<BookModel>>((
  ref,
) async {
  final repo = ref.read(bookRepositoryProvider);
  final result = await repo.getBooks(isFavorited: true);
  return result.fold((_) => [], (p) => p.data);
});

final myUploadedBooksProvider = FutureProvider.autoDispose<List<BookModel>>((
  ref,
) async {
  final repo = ref.read(bookRepositoryProvider);
  final result = await repo.getBooks(myUploads: true);
  return result.fold((_) => [], (p) => p.data);
});

// ─── Screen ──────────────────────────────────────────────────────────────────

class BookshelfScreen extends ConsumerWidget {
  const BookshelfScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text('bookshelf'.tr())),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.library_books_outlined,
                size: 72,
                color: AppColors.border,
              ),
              const SizedBox(height: 16),
              Text(
                'login_to_see_bookshelf'.tr(),
                style: AppTextStyles.bodyLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.push(RouteNames.login),
                child: Text('login'.tr()),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('bookshelf'.tr()),
          bottom: TabBar(
            tabs: [
              Tab(text: 'favorites'.tr()),
              Tab(text: 'my_uploads'.tr()),
            ],
          ),
        ),
        body: TabBarView(children: [_FavoritesTab(), _MyUploadsTab()]),
      ),
    );
  }
}

class _FavoritesTab extends ConsumerWidget {
  Future<void> _refreshBooks(WidgetRef ref) async {
    ref.invalidate(favoriteBooksProvider);
    await ref.read(favoriteBooksProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(favoriteBooksProvider);
    return RefreshIndicator(
      onRefresh: () => _refreshBooks(ref),
      color: AppColors.primary,
      child: async.when(
        loading: () => const LotusLoader(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(favoriteBooksProvider),
        ),
        data: (books) => books.isEmpty
            ? ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: _EmptyShelf(
                      icon: Icons.favorite_border_rounded,
                      label: 'no_favorites'.tr(),
                    ),
                  ),
                ],
              )
            : _BooksGrid(books: books),
      ),
    );
  }
}

class _MyUploadsTab extends ConsumerWidget {
  Future<void> _refreshBooks(WidgetRef ref) async {
    ref.invalidate(myUploadsNotifierProvider);
    await ref.read(myUploadsNotifierProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myUploadsNotifierProvider);
    return RefreshIndicator(
      onRefresh: () => _refreshBooks(ref),
      color: AppColors.primary,
      child: async.when(
        loading: () => const LotusLoader(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(myUploadsNotifierProvider),
        ),
        data: (books) => books.isEmpty
            ? ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: _EmptyShelf(
                      icon: Icons.upload_file_rounded,
                      label: 'no_uploads'.tr(),
                    ),
                  ),
                ],
              )
            : _MyUploadsGrid(books: books),
      ),
    );
  }
}

class _BooksGrid extends StatelessWidget {
  final List<BookModel> books;
  const _BooksGrid({required this.books});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemCount: books.length,
      itemBuilder: (_, i) => _FavoriteBookCard(book: books[i]),
    );
  }
}

class _FavoriteBookCard extends ConsumerStatefulWidget {
  final BookModel book;
  const _FavoriteBookCard({required this.book});

  @override
  ConsumerState<_FavoriteBookCard> createState() => _FavoriteBookCardState();
}

class _FavoriteBookCardState extends ConsumerState<_FavoriteBookCard> {
  bool _isFavorited = true;

  Future<void> _toggleFavorite() async {
    setState(() => _isFavorited = !_isFavorited);
    final repo = ref.read(bookRepositoryProvider);
    final result = await repo.toggleFavorite(widget.book.id);
    result.fold(
      (error) {
        if (mounted) setState(() => _isFavorited = !_isFavorited);
      },
      (isFav) {
        if (mounted) {
          setState(() => _isFavorited = isFav);
          if (!isFav) ref.invalidate(favoriteBooksProvider);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    return GestureDetector(
      onTap: () => context.push(RouteNames.bookDetailPath(book.id)),
      child: Container(
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
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: BookThumbnail(
                      book: book,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: _toggleFavorite,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isFavorited
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 20,
                          color: _isFavorited
                              ? AppColors.primary
                              : AppColors.textLight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.titleKm ?? book.title,
                    style: AppTextStyles.cardTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    book.author,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── My Uploads Grid & Card (with actions) ────────────────────────────────

class _MyUploadsGrid extends StatelessWidget {
  final List<BookModel> books;
  const _MyUploadsGrid({required this.books});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemCount: books.length,
      itemBuilder: (_, i) => _UploadedBookCard(book: books[i]),
    );
  }
}

class _UploadedBookCard extends ConsumerWidget {
  final BookModel book;
  const _UploadedBookCard({required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.bookDetailPath(book.id)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.fromBorderSide(
            BorderSide(
              color: book.isPrivate
                  ? AppColors.textLight.withValues(alpha: 0.4)
                  : AppColors.border,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: BookThumbnail(
                      book: book,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  // Private badge
                  if (book.isPrivate)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_rounded,
                                size: 10, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(
                              'Only me',
                              style: AppTextStyles.labelSmall
                                  .copyWith(color: Colors.white, fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // 3-dot action button
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _BookActionsMenu(book: book),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.titleKm ?? book.title,
                    style: AppTextStyles.cardTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          book.author,
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _StatusDot(status: book.status),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'approved' => AppColors.success,
      'rejected' => AppColors.error,
      _ => AppColors.accent,
    };
    return Tooltip(
      message: status,
      child: Container(
        width: 8,
        height: 8,
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _BookActionsMenu extends ConsumerWidget {
  final BookModel book;
  const _BookActionsMenu({required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showMenu(context, ref),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.more_vert_rounded, size: 16, color: Colors.white),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _BookActionsSheet(
        book: book,
        onEdit: () {
          Navigator.pop(context);
          _showEditSheet(context, ref);
        },
        onToggleVisibility: () {
          Navigator.pop(context);
          _toggleVisibility(context, ref);
        },
        onDelete: () {
          Navigator.pop(context);
          _confirmDelete(context, ref);
        },
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _EditBookSheet(
        book: book,
        onSave: (data) async {
          final err =
              await ref.read(myUploadsNotifierProvider.notifier).updateBook(
                    bookId: book.id,
                    title: data['title'] as String?,
                    titleKm: data['title_km'] as String?,
                    description: data['description'] as String?,
                    descriptionKm: data['description_km'] as String?,
                    isPrivate: data['is_private'] as bool?,
                  );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(err ?? 'Book updated.'),
              backgroundColor:
                  err != null ? AppColors.error : AppColors.success,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
      ),
    );
  }

  Future<void> _toggleVisibility(BuildContext context, WidgetRef ref) async {
    final err = await ref
        .read(myUploadsNotifierProvider.notifier)
        .toggleVisibility(book.id);
    if (context.mounted) {
      final newPrivate = !book.isPrivate;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err ??
            (newPrivate ? 'Set to Private (Only me).' : 'Set to Public.')),
        backgroundColor: err != null ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text(
            'Delete “${book.titleKm ?? book.title}”? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final err = await ref
                  .read(myUploadsNotifierProvider.notifier)
                  .deleteBook(book.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(err ?? 'Book deleted.'),
                  backgroundColor:
                      err != null ? AppColors.error : AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Actions bottom sheet ────────────────────────────────────────────────

class _BookActionsSheet extends StatelessWidget {
  final BookModel book;
  final VoidCallback onEdit;
  final VoidCallback onToggleVisibility;
  final VoidCallback onDelete;

  const _BookActionsSheet({
    required this.book,
    required this.onEdit,
    required this.onToggleVisibility,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              book.titleKm ?? book.title,
              style: AppTextStyles.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
            title: const Text('Edit'),
            onTap: onEdit,
          ),
          ListTile(
            leading: Icon(
              book.isPrivate
                  ? Icons.public_rounded
                  : Icons.lock_outline_rounded,
              color: AppColors.primary,
            ),
            title: Text(
                book.isPrivate ? 'Set to Public' : 'Set to Private (Only me)'),
            onTap: onToggleVisibility,
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error),
            title:
                const Text('Delete', style: TextStyle(color: AppColors.error)),
            onTap: onDelete,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Edit book bottom sheet ─────────────────────────────────────────────

class _EditBookSheet extends StatefulWidget {
  final BookModel book;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _EditBookSheet({required this.book, required this.onSave});

  @override
  State<_EditBookSheet> createState() => _EditBookSheetState();
}

class _EditBookSheetState extends State<_EditBookSheet> {
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
            Row(
              children: [
                Text('Edit Book', style: AppTextStyles.titleMedium),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),
            _buildField('Title (English)', _titleEn),
            const SizedBox(height: 10),
            _buildField('Title (Khmer)', _titleKm),
            const SizedBox(height: 10),
            _buildField('Description (English)', _descEn, maxLines: 3),
            const SizedBox(height: 10),
            _buildField('Description (Khmer)', _descKm, maxLines: 3),
            const SizedBox(height: 10),
            _buildField('Year Published', _publishYear,
                keyboardType: TextInputType.number),
            const SizedBox(height: 14),
            // Visibility
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _VisibilityTile(
                    icon: Icons.public_rounded,
                    title: 'Public',
                    subtitle: 'Everyone can see this book',
                    selected: !_isPrivate,
                    onTap: () => setState(() => _isPrivate = false),
                  ),
                  const Divider(height: 1),
                  _VisibilityTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Only me',
                    subtitle: 'Only you can see this book',
                    selected: _isPrivate,
                    onTap: () => setState(() => _isPrivate = true),
                  ),
                ],
              ),
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

  Widget _buildField(String label, TextEditingController ctrl,
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

class _VisibilityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _VisibilityTile({
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
      leading: Icon(
        icon,
        color: selected ? AppColors.primary : AppColors.textLight,
      ),
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

class _EmptyShelf extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptyShelf({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 72, color: AppColors.border),
          const SizedBox(height: 12),
          Text(label, style: AppTextStyles.bodyLarge),
        ],
      ),
    );
  }
}
