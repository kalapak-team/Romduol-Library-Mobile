import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/book_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/book/book_thumbnail.dart';

class AdminBooksScreen extends ConsumerStatefulWidget {
  const AdminBooksScreen({super.key});

  @override
  ConsumerState<AdminBooksScreen> createState() => _AdminBooksScreenState();
}

class _AdminBooksScreenState extends ConsumerState<AdminBooksScreen> {
  final _searchController = TextEditingController();
  String _statusFilter = '';
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(adminBooksProvider.notifier).search(query);
    });
  }

  void _onStatusFilterChanged(String status) {
    setState(() => _statusFilter = status);
    ref.read(adminBooksProvider.notifier).filterByStatus(status);
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(adminBooksProvider);
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('manage_books'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(adminBooksProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'search_books'.tr(),
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.textLight),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'all'.tr(),
                        selected: _statusFilter.isEmpty,
                        onTap: () => _onStatusFilterChanged(''),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'pending'.tr(),
                        selected: _statusFilter == 'pending',
                        onTap: () => _onStatusFilterChanged('pending'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'approved'.tr(),
                        selected: _statusFilter == 'approved',
                        onTap: () => _onStatusFilterChanged('approved'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'rejected'.tr(),
                        selected: _statusFilter == 'rejected',
                        onTap: () => _onStatusFilterChanged('rejected'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Book list
          Expanded(
            child: booksAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('error_occurred'.tr(),
                        style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 8),
                    Text(e.toString(), style: AppTextStyles.bodySmall),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(adminBooksProvider.notifier).refresh(),
                      child: Text('retry'.tr()),
                    ),
                  ],
                ),
              ),
              data: (books) {
                if (books.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.menu_book_outlined,
                            size: 64, color: AppColors.textLight),
                        const SizedBox(height: 12),
                        Text('no_books_found'.tr(),
                            style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(adminBooksProvider.notifier).refresh(),
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: books.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => _BookCard(
                      book: books[index],
                      onApprove: books[index].status == 'pending'
                          ? () => _approveBook(books[index].id)
                          : null,
                      onReject: books[index].status == 'pending'
                          ? () => _showRejectDialog(context, books[index].id)
                          : null,
                      onFeature: books[index].status == 'approved'
                          ? () => _featureBook(books[index].id)
                          : null,
                      onEdit: currentUserId != null &&
                              books[index].userId == currentUserId
                          ? () => _showEditSheet(context, books[index])
                          : null,
                      onDelete: () => _confirmAction(
                        context,
                        'confirm_delete_book'.tr(),
                        () => _deleteBook(books[index].id),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmAction(
      BuildContext context, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('confirm'.tr(), style: AppTextStyles.titleMedium),
        content: Text(message, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: Text('confirm'.tr(),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String bookId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('reject'.tr(), style: AppTextStyles.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('reject_reason_hint'.tr(), style: AppTextStyles.bodyMedium),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'reject_reason_placeholder'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              _rejectBook(bookId, reason: reasonController.text.trim());
            },
            child: Text('reject'.tr(),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, BookModel book) {
    final currentUserId = ref.read(authStateProvider).valueOrNull?.id;
    if (currentUserId == null || book.userId != currentUserId) {
      _showSnackBar('Forbidden. You can only edit your own books.',
          isError: true);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _AdminEditBookSheet(
        book: book,
        onSave: (data) async {
          final error = await ref
              .read(adminBooksProvider.notifier)
              .updateBook(book.id, data);
          if (!mounted) return;
          _showSnackBar(error ?? 'book_updated_success'.tr(),
              isError: error != null);
        },
      ),
    );
  }

  Future<void> _approveBook(String id) async {
    final error = await ref.read(adminBooksProvider.notifier).approveBook(id);
    if (!mounted) return;
    _showSnackBar(error ?? 'book_approved_success'.tr(),
        isError: error != null);
  }

  Future<void> _rejectBook(String id, {String? reason}) async {
    final error = await ref
        .read(adminBooksProvider.notifier)
        .rejectBook(id, reason: reason);
    if (!mounted) return;
    _showSnackBar(error ?? 'book_rejected_success'.tr(),
        isError: error != null);
  }

  Future<void> _featureBook(String id) async {
    final error = await ref.read(adminBooksProvider.notifier).featureBook(id);
    if (!mounted) return;
    _showSnackBar(error ?? 'book_featured_success'.tr(),
        isError: error != null);
  }

  Future<void> _deleteBook(String id) async {
    final error = await ref.read(adminBooksProvider.notifier).deleteBook(id);
    if (!mounted) return;
    _showSnackBar(error ?? 'book_deleted_success'.tr(), isError: error != null);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ── Book Card ─────────────────────────────────────────────────────────────

class _BookCard extends StatelessWidget {
  final BookModel book;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onFeature;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;

  const _BookCard({
    required this.book,
    this.onApprove,
    this.onReject,
    this.onFeature,
    this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: book.status == 'rejected'
              ? AppColors.error.withValues(alpha: 0.3)
              : book.status == 'pending'
                  ? AppColors.accent.withValues(alpha: 0.3)
                  : AppColors.border,
        ),
      ),
      color: book.status == 'rejected'
          ? AppColors.error.withValues(alpha: 0.04)
          : book.status == 'pending'
              ? AppColors.accent.withValues(alpha: 0.04)
              : AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book info row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 56,
                    height: 76,
                    child: BookThumbnail(
                      book: book,
                      width: 56,
                      height: 76,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Book details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              book.titleKm ?? book.title,
                              style: AppTextStyles.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _StatusBadge(status: book.status),
                          if (book.isFeatured) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded,
                                      size: 12, color: AppColors.accent),
                                  const SizedBox(width: 2),
                                  Text(
                                    'featured'.tr(),
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.authorKm ?? book.author,
                        style: AppTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (book.category != null)
                        Text(
                          book.category!.nameKm ?? book.category!.name,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textLight),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Stats row
            Row(
              children: [
                _StatBadge(
                    icon: Icons.download_outlined,
                    value: '${book.downloadCount}'),
                const SizedBox(width: 12),
                _StatBadge(
                    icon: Icons.visibility_outlined,
                    value: '${book.viewCount}'),
                const SizedBox(width: 12),
                _StatBadge(
                  icon: Icons.star_rounded,
                  value: book.avgRating.toStringAsFixed(1),
                ),
                const SizedBox(width: 12),
                _StatBadge(
                  icon: Icons.description_outlined,
                  value: book.fileType.toUpperCase(),
                ),
                if (book.fileSizeKb != null) ...[
                  const SizedBox(width: 12),
                  _StatBadge(
                    icon: Icons.storage_outlined,
                    value: _formatFileSize(book.fileSizeKb!),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 8),
            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (onEdit != null)
                  _ActionButton(
                    icon: Icons.edit_outlined,
                    label: 'edit'.tr(),
                    color: AppColors.primary,
                    onTap: onEdit!,
                  ),
                if (onApprove != null)
                  _ActionButton(
                    icon: Icons.check_circle_outline,
                    label: 'approve'.tr(),
                    color: AppColors.success,
                    onTap: onApprove!,
                  ),
                if (onReject != null)
                  _ActionButton(
                    icon: Icons.cancel_outlined,
                    label: 'reject'.tr(),
                    color: AppColors.error,
                    onTap: onReject!,
                  ),
                if (onFeature != null)
                  _ActionButton(
                    icon: book.isFeatured
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    label: book.isFeatured ? 'unfeature'.tr() : 'feature'.tr(),
                    color: AppColors.accent,
                    onTap: onFeature!,
                  ),
                _ActionButton(
                  icon: Icons.delete_outline,
                  label: 'delete'.tr(),
                  color: AppColors.error,
                  onTap: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int kb) {
    if (kb >= 1024) {
      return '${(kb / 1024).toStringAsFixed(1)} MB';
    }
    return '$kb KB';
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (status) {
      case 'approved':
        color = AppColors.success;
        break;
      case 'rejected':
        color = AppColors.error;
        break;
      case 'pending':
        color = AppColors.accent;
        break;
      default:
        color = AppColors.textLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.tr(),
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Stat Badge ────────────────────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;

  const _StatBadge({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textLight),
        const SizedBox(width: 4),
        Text(value, style: AppTextStyles.bodySmall),
      ],
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall
                  .copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter Chip ───────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: selected ? Colors.white : AppColors.textMid,
          ),
        ),
      ),
    );
  }
}

// ── Admin Edit Book Sheet ─────────────────────────────────────────────────

class _AdminEditBookSheet extends StatefulWidget {
  final BookModel book;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _AdminEditBookSheet({required this.book, required this.onSave});

  @override
  State<_AdminEditBookSheet> createState() => _AdminEditBookSheetState();
}

class _AdminEditBookSheetState extends State<_AdminEditBookSheet> {
  late final TextEditingController _titleEn;
  late final TextEditingController _titleKm;
  late final TextEditingController _descEn;
  late final TextEditingController _descKm;
  late final TextEditingController _publishYear;
  late bool _isPrivate;
  late bool _isFeatured;
  late String _status;
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
    _isFeatured = widget.book.isFeatured;
    _status = widget.book.status;
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
            const SizedBox(height: 12),
            // Status
            Text('Status', style: AppTextStyles.labelMedium),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: ['pending', 'approved', 'rejected'].map((s) {
                final selected = _status == s;
                return ChoiceChip(
                  label: Text(s),
                  selected: selected,
                  onSelected: (_) => setState(() => _status = s),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textMid),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // Visibility + Featured
            SwitchListTile(
              title: const Text('Private (Only me)'),
              value: _isPrivate,
              onChanged: (v) => setState(() => _isPrivate = v),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            SwitchListTile(
              title: const Text('Featured'),
              value: _isFeatured,
              onChanged: (v) => setState(() => _isFeatured = v),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            const SizedBox(height: 12),
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
      'is_featured': _isFeatured,
      'status': _status,
    });
    if (mounted) Navigator.pop(context);
    setState(() => _saving = false);
  }
}
