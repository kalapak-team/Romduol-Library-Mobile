import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/book_remote_datasource.dart';
import '../../data/models/book_model.dart';
import '../../data/models/paginated_response.dart';
import '../../data/models/review_model.dart';
import '../../data/repositories/book_repository.dart';

final bookRemoteDatasourceProvider = Provider((_) => BookRemoteDataSource());

final bookRepositoryProvider = Provider(
  (ref) => BookRepository(ref.read(bookRemoteDatasourceProvider)),
);

// Featured books
final featuredBooksProvider = FutureProvider<List<BookModel>>((ref) async {
  final repo = ref.read(bookRepositoryProvider);
  final result = await repo.getFeaturedBooks();
  return result.fold((e) => throw Exception(e), (books) => books);
});

// New arrivals
final newArrivalsProvider = FutureProvider<List<BookModel>>((ref) async {
  final repo = ref.read(bookRepositoryProvider);
  final result = await repo.getNewArrivals();
  return result.fold((e) => throw Exception(e), (books) => books);
});

// Catalog with filters
class CatalogParams {
  final int page;
  final String? categoryId;
  final String? language;
  final String sortBy;

  const CatalogParams({
    this.page = 1,
    this.categoryId,
    this.language,
    this.sortBy = 'newest',
  });

  CatalogParams copyWith({
    int? page,
    String? categoryId,
    String? language,
    String? sortBy,
  }) =>
      CatalogParams(
        page: page ?? this.page,
        categoryId: categoryId ?? this.categoryId,
        language: language ?? this.language,
        sortBy: sortBy ?? this.sortBy,
      );
}

final catalogParamsProvider = StateProvider<CatalogParams>(
  (_) => const CatalogParams(),
);

final catalogBooksProvider = FutureProvider<PaginatedResponse<BookModel>>((
  ref,
) async {
  final params = ref.watch(catalogParamsProvider);
  final repo = ref.read(bookRepositoryProvider);
  final result = await repo.getBooks(
    page: params.page,
    categoryId: params.categoryId,
    language: params.language,
    sortBy: params.sortBy,
  );
  return result.fold((e) => throw Exception(e), (r) => r);
});

// Single book detail
final bookDetailProvider =
    FutureProvider.autoDispose.family<BookModel, String>((
  ref,
  id,
) async {
  final repo = ref.read(bookRepositoryProvider);
  final result = await repo.getBookById(id);
  return result.fold((e) => throw Exception(e), (b) => b);
});

// Search query state
final searchQueryProvider = StateProvider<String>((_) => '');

final searchResultsProvider =
    FutureProvider.family<PaginatedResponse<BookModel>, String>((
  ref,
  query,
) async {
  if (query.isEmpty) {
    return PaginatedResponse<BookModel>(
      data: [],
      currentPage: 1,
      lastPage: 1,
      perPage: 20,
      total: 0,
    );
  }
  final repo = ref.read(bookRepositoryProvider);
  final result = await repo.searchBooks(query: query);
  return result.fold((e) => throw Exception(e), (r) => r);
});

// Upload progress
final uploadProgressProvider = StateProvider<double>((_) => 0.0);

// Book reviews
final bookReviewsProvider = FutureProvider.family
    .autoDispose<List<ReviewModel>, String>((ref, bookId) async {
  final repo = ref.read(bookRepositoryProvider);
  final result = await repo.getReviews(bookId);
  return result.fold((e) => throw Exception(e), (r) => r);
});

// My reviews (for profile screen)
final myReviewsProvider =
    FutureProvider.autoDispose<List<ReviewModel>>((ref) async {
  final repo = ref.read(bookRepositoryProvider);
  final result = await repo.getMyReviews();
  return result.fold((e) => throw Exception(e), (r) => r);
});

// ── My Uploads (with edit / delete / visibility) ─────────────────────────────

final myUploadsNotifierProvider =
    AsyncNotifierProvider.autoDispose<MyUploadsNotifier, List<BookModel>>(
  MyUploadsNotifier.new,
);

class MyUploadsNotifier extends AutoDisposeAsyncNotifier<List<BookModel>> {
  @override
  Future<List<BookModel>> build() async {
    final repo = ref.read(bookRepositoryProvider);
    final result = await repo.getBooks(myUploads: true);
    return result.fold((e) => throw Exception(e), (p) => p.data);
  }

  Future<String?> updateBook({
    required String bookId,
    String? title,
    String? titleKm,
    String? description,
    String? descriptionKm,
    int? publishYear,
    bool? isPrivate,
  }) async {
    final repo = ref.read(bookRepositoryProvider);
    final result = await repo.updateBook(
      bookId: bookId,
      title: title,
      titleKm: titleKm,
      description: description,
      descriptionKm: descriptionKm,
      publishYear: publishYear,
      isPrivate: isPrivate,
    );
    return result.fold(
      (err) => err,
      (updated) {
        final current = state.valueOrNull;
        if (current != null) {
          state = AsyncData(
            current.map((b) => b.id == bookId ? updated : b).toList(),
          );
        }
        return null;
      },
    );
  }

  Future<String?> deleteBook(String bookId) async {
    final repo = ref.read(bookRepositoryProvider);
    final result = await repo.deleteBook(bookId);
    return result.fold(
      (err) => err,
      (_) {
        final current = state.valueOrNull;
        if (current != null) {
          state = AsyncData(current.where((b) => b.id != bookId).toList());
        }
        return null;
      },
    );
  }

  Future<String?> toggleVisibility(String bookId) async {
    final current = state.valueOrNull;
    final book = current?.firstWhere((b) => b.id == bookId);
    if (book == null) return 'Book not found';
    return updateBook(bookId: bookId, isPrivate: !book.isPrivate);
  }
}
