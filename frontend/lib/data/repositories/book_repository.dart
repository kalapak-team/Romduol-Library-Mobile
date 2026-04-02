import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../core/network/api_exception.dart';
import '../datasources/remote/book_remote_datasource.dart';
import '../models/book_model.dart';
import '../models/paginated_response.dart';
import '../models/review_model.dart';

class BookRepository {
  final BookRemoteDataSource _remote;

  BookRepository(this._remote);

  Future<Either<String, PaginatedResponse<BookModel>>> getBooks({
    int page = 1,
    int perPage = 20,
    String? categoryId,
    String? language,
    String? sortBy,
    bool? isFavorited,
    bool? myUploads,
    String? uploaderId,
  }) async {
    try {
      final result = await _remote.getBooks(
        page: page,
        perPage: perPage,
        categoryId: categoryId,
        language: language,
        sortBy: sortBy,
        isFavorited: isFavorited,
        myUploads: myUploads,
        uploaderId: uploaderId,
      );
      return Right(result);
    } on ApiException catch (e) {
      return Left(e.message);
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }

  Future<Either<String, BookModel>> getBookById(String id) async {
    try {
      return Right(await _remote.getBookById(id));
    } on ApiException catch (e) {
      return Left(e.message);
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }

  Future<Either<String, List<BookModel>>> getFeaturedBooks() async {
    try {
      return Right(await _remote.getFeaturedBooks());
    } on ApiException catch (e) {
      return Left(e.message);
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }

  Future<Either<String, List<BookModel>>> getNewArrivals() async {
    try {
      return Right(await _remote.getNewArrivals());
    } on ApiException catch (e) {
      return Left(e.message);
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }

  Future<Either<String, PaginatedResponse<BookModel>>> searchBooks({
    required String query,
    int page = 1,
    String? language,
    String? categoryId,
  }) async {
    try {
      final result = await _remote.searchBooks(
        query: query,
        page: page,
        language: language,
        categoryId: categoryId,
      );
      return Right(result);
    } on ApiException catch (e) {
      return Left(e.message);
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }

  Future<Either<String, BookModel>> uploadBook({
    required String titleEn,
    String? titleKm,
    required String author,
    String? description,
    String? descriptionKm,
    String? publisher,
    int? publishYear,
    required String language,
    Uint8List? coverBytes,
    String? coverFileName,
    Uint8List? bookBytes,
    String? bookFileName,
    String? bookLink,
    void Function(double)? onProgress,
  }) async {
    try {
      final result = await _remote.uploadBook(
        coverBytes: coverBytes,
        coverFileName: coverFileName,
        bookBytes: bookBytes,
        bookFileName: bookFileName,
        bookLink: bookLink,
        bookData: {
          'title': titleEn,
          'title_km': titleKm,
          'author': author,
          'description': description,
          'description_km': descriptionKm,
          'publisher': publisher,
          'publication_year': publishYear,
          'language': language,
        },
        onSendProgress: onProgress != null
            ? (sent, total) => onProgress(total > 0 ? sent / total : 0)
            : null,
      );
      return Right(result);
    } on ApiException catch (e) {
      return Left(e.message);
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }

  Future<Either<String, BookModel>> updateBook({
    required String bookId,
    String? title,
    String? titleKm,
    String? author,
    String? description,
    String? descriptionKm,
    int? publishYear,
    bool? isPrivate,
  }) async {
    try {
      final result = await _remote.updateBook(
        bookId: bookId,
        title: title,
        titleKm: titleKm,
        author: author,
        description: description,
        descriptionKm: descriptionKm,
        publishYear: publishYear,
        isPrivate: isPrivate,
      );
      return Right(result);
    } on ApiException catch (e) {
      return Left(e.message);
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }

  Future<Either<String, void>> deleteBook(String bookId) async {
    try {
      await _remote.deleteBook(bookId);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(e.message);
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }

  Future<Either<String, List<ReviewModel>>> getReviews(String bookId) async {
    try {
      return Right(await _remote.getReviews(bookId));
    } on ApiException catch (e) {
      return Left(e.message);
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }

  Future<Either<String, ReviewModel>> addReview({
    required String bookId,
    required int rating,
    String? title,
    String? body,
  }) async {
    try {
      final result = await _remote.addReview(
        bookId: bookId,
        rating: rating,
        title: title,
        body: body,
      );
      return Right(result);
    } on ApiException catch (e) {
      return Left(e.message);
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }

  Future<Either<String, bool>> toggleFavorite(String bookId) async {
    try {
      return Right(await _remote.toggleFavorite(bookId));
    } on ApiException catch (e) {
      return Left(e.message);
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }

  Future<Either<String, List<ReviewModel>>> getMyReviews() async {
    try {
      return Right(await _remote.getMyReviews());
    } on ApiException catch (e) {
      return Left(e.message);
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }
}
