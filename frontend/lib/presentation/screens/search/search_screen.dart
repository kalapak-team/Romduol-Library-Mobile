import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/route_names.dart';
import '../../../data/models/book_model.dart';
import '../../providers/book_provider.dart';
import '../../widgets/book/book_thumbnail.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/lotus_loader.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String? query;
  const SearchScreen({super.key, this.query});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final List<String> _recentSearches = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    if (widget.query != null) {
      _controller.text = widget.query!;
      _query = widget.query!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String q) {
    if (q.trim().isEmpty) return;
    setState(() {
      _query = q.trim();
      if (!_recentSearches.contains(_query)) {
        _recentSearches.insert(0, _query);
        if (_recentSearches.length > 10) _recentSearches.removeLast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'search_hint'.tr(),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          style: AppTextStyles.bodyLarge,
          textInputAction: TextInputAction.search,
          onSubmitted: _search,
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: _query.isEmpty
          ? _RecentSearches(
              searches: _recentSearches,
              onTap: (s) {
                _controller.text = s;
                _search(s);
              },
            )
          : _SearchResults(query: _query),
    );
  }
}

class _RecentSearches extends StatelessWidget {
  final List<String> searches;
  final ValueChanged<String> onTap;
  const _RecentSearches({required this.searches, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (searches.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_rounded, size: 72, color: AppColors.border),
            const SizedBox(height: 8),
            Text('search_hint'.tr(), style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('recent_searches'.tr(), style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: searches
              .map(
                (s) => ActionChip(
                  label: Text(s),
                  avatar: const Icon(Icons.history_rounded, size: 16),
                  onPressed: () => onTap(s),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _SearchResults extends ConsumerWidget {
  final String query;
  const _SearchResults({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(searchResultsProvider(query));
    return async.when(
      loading: () => const LotusLoader(),
      error: (e, _) => ErrorView(message: e.toString()),
      data: (paginated) => paginated.data.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.search_off_rounded,
                    size: 72,
                    color: AppColors.border,
                  ),
                  const SizedBox(height: 8),
                  Text('no_results'.tr()),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: paginated.data.length,
              itemBuilder: (_, i) => _SearchResultTile(book: paginated.data[i]),
            ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final BookModel book;
  const _SearchResultTile({required this.book});

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
            BookThumbnail(book: book, width: 56, height: 80),
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
                  const SizedBox(height: 2),
                  Text(book.author, style: AppTextStyles.caption),
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
