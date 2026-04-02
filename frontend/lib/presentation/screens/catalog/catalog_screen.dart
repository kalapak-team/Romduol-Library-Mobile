import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/route_names.dart';
import '../../../data/models/book_model.dart';
import '../../providers/book_provider.dart';
import '../../widgets/book/book_thumbnail.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/lotus_loader.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  static const _pageSize = 20;
  final PagingController<int, BookModel> _pagingController = PagingController(
    firstPageKey: 1,
  );
  String _sortBy = 'newest';
  String? _selectedLanguage;
  bool _isGrid = true;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener(_fetchPage);
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final repo = ref.read(bookRepositoryProvider);
      final result = await repo.getBooks(
        page: pageKey,
        perPage: _pageSize,
        language: _selectedLanguage,
        sortBy: _sortBy,
      );
      if (!mounted) return;

      result.fold((err) {
        if (!mounted) return;
        _pagingController.error = err;
      }, (paginated) {
        if (!mounted) return;
        final isLast = paginated.currentPage >= paginated.lastPage;
        if (isLast) {
          _pagingController.appendLastPage(paginated.data);
        } else {
          _pagingController.appendPage(paginated.data, pageKey + 1);
        }
      });
    } catch (e) {
      if (!mounted) return;
      _pagingController.error = e;
    }
  }

  Future<void> _refreshBooks() async {
    _pagingController.refresh();
  }

  void _showFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(
        currentSort: _sortBy,
        currentLanguage: _selectedLanguage,
        onApply: (sort, lang) {
          setState(() {
            _sortBy = sort;
            _selectedLanguage = lang;
          });
          Navigator.pop(context);
          _refreshBooks();
        },
      ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('nav_catalog'.tr()),
        actions: [
          IconButton(
            icon: Icon(_isGrid ? Icons.list_rounded : Icons.grid_view_rounded),
            onPressed: () => setState(() => _isGrid = !_isGrid),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: _showFilter,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: GestureDetector(
              onTap: () => context.push(RouteNames.search),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: const Border.fromBorderSide(
                    BorderSide(color: AppColors.border),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'search_hint'.tr(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshBooks,
              color: AppColors.primary,
              child: _isGrid
                  ? PagedGridView<int, BookModel>(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      pagingController: _pagingController,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.62,
                      ),
                      builderDelegate: PagedChildBuilderDelegate<BookModel>(
                        itemBuilder: (_, book, __) =>
                            _CatalogBookCard(book: book),
                        firstPageProgressIndicatorBuilder: (_) =>
                            const LotusLoader(),
                        newPageProgressIndicatorBuilder: (_) =>
                            const InlineLoader(),
                        firstPageErrorIndicatorBuilder: (_) => ErrorView(
                          message: _pagingController.error.toString(),
                          onRetry: _refreshBooks,
                        ),
                        noItemsFoundIndicatorBuilder: (_) =>
                            const EmptyStateView(),
                      ),
                    )
                  : PagedListView<int, BookModel>(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      pagingController: _pagingController,
                      builderDelegate: PagedChildBuilderDelegate<BookModel>(
                        itemBuilder: (_, book, __) =>
                            _CatalogBookListTile(book: book),
                        firstPageProgressIndicatorBuilder: (_) =>
                            const LotusLoader(),
                        newPageProgressIndicatorBuilder: (_) =>
                            const InlineLoader(),
                        firstPageErrorIndicatorBuilder: (_) => ErrorView(
                          message: _pagingController.error.toString(),
                          onRetry: _refreshBooks,
                        ),
                        noItemsFoundIndicatorBuilder: (_) =>
                            const EmptyStateView(),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogBookCard extends StatelessWidget {
  final BookModel book;
  const _CatalogBookCard({required this.book});

  @override
  Widget build(BuildContext context) {
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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: BookThumbnail(
                book: book,
                width: double.infinity,
                height: 150,
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
                  const SizedBox(height: 2),
                  Text(
                    book.author,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: AppColors.accent,
                      ),
                      Text(
                        ' ${book.avgRating.toStringAsFixed(1)}',
                        style: AppTextStyles.caption,
                      ),
                      const Spacer(),
                      Text(
                        book.fileType.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
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

class _CatalogBookListTile extends StatelessWidget {
  final BookModel book;
  const _CatalogBookListTile({required this.book});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.bookDetailPath(book.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
            BookThumbnail(book: book, width: 70, height: 100),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.titleKm ?? book.title,
                    style: AppTextStyles.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(book.author, style: AppTextStyles.bodySmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: AppColors.accent,
                      ),
                      Text(
                        ' ${book.avgRating.toStringAsFixed(1)}',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.download_outlined,
                        size: 14,
                        color: AppColors.textLight,
                      ),
                      Text(
                        ' ${book.downloadCount}',
                        style: AppTextStyles.bodySmall,
                      ),
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

class _FilterSheet extends StatefulWidget {
  final String currentSort;
  final String? currentLanguage;
  final void Function(String sort, String? lang) onApply;

  const _FilterSheet({
    required this.currentSort,
    this.currentLanguage,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _sort;
  String? _lang;

  @override
  void initState() {
    super.initState();
    _sort = widget.currentSort;
    _lang = widget.currentLanguage;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('filter'.tr(), style: AppTextStyles.headlineMedium),
          const SizedBox(height: 16),
          Text('sort_by'.tr(), style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final s in ['newest', 'most_downloaded', 'top_rated', 'az'])
                ChoiceChip(
                  label: Text(('sort_$s').tr()),
                  selected: _sort == s,
                  onSelected: (_) => setState(() => _sort = s),
                  selectedColor: AppColors.primaryWithOpacity12,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('language'.tr(), style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final l in ['km', 'en', 'fr', 'zh'])
                ChoiceChip(
                  label: Text(('lang_$l').tr()),
                  selected: _lang == l,
                  onSelected: (v) => setState(() => _lang = v ? l : null),
                  selectedColor: AppColors.primaryWithOpacity12,
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _sort = 'newest';
                      _lang = null;
                    });
                  },
                  child: Text('clear_filter'.tr()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => widget.onApply(_sort, _lang),
                  child: Text('apply_filter'.tr()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Re-export EmptyStateView for local use
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.library_books_outlined,
            size: 72,
            color: AppColors.border,
          ),
          const SizedBox(height: 12),
          Text('empty_library'.tr(), style: AppTextStyles.titleLarge),
        ],
      ),
    );
  }
}
