import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../models/book_model.dart';
import '../../models/paginated_response.dart';
import '../../models/review_model.dart';

class BookRemoteDataSource {
  final Dio _dio = DioClient.instance;

  dynamic _extractPayload(dynamic responseData) {
    if (responseData is Map<String, dynamic> &&
        responseData.containsKey('data')) {
      return responseData['data'];
    }
    return responseData;
  }

  PaginatedResponse<BookModel> _parsePaginatedBooks(dynamic data) {
    if (data is List) {
      final books = data
          .map((e) => BookModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return PaginatedResponse<BookModel>(
        data: books,
        currentPage: 1,
        lastPage: 1,
        perPage: books.length,
        total: books.length,
      );
    }

    return PaginatedResponse.fromJson(
      data as Map<String, dynamic>,
      BookModel.fromJson,
    );
  }

  Future<PaginatedResponse<BookModel>> getBooks({
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
      final response = await _dio.get(
        ApiEndpoints.books,
        queryParameters: {
          'page': page,
          'per_page': perPage,
          if (categoryId != null) 'category_id': categoryId,
          if (language != null) 'language': language,
          if (sortBy != null) 'sort_by': sortBy,
          if (isFavorited == true) 'is_favorited': 1,
          if (myUploads == true) 'my_uploads': 1,
          if (uploaderId != null) 'uploader_id': uploaderId,
        },
      );
      return _parsePaginatedBooks(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<BookModel> getBookById(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.bookDetail(id));
      final data = (response.data as Map<String, dynamic>)['data'];
      return BookModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<BookModel>> getFeaturedBooks() async {
    try {
      final response = await _dio.get(ApiEndpoints.featuredBooks);
      final data = (response.data as Map<String, dynamic>)['data'] as List;
      return data
          .map((e) => BookModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<BookModel>> getNewArrivals() async {
    try {
      final response = await _dio.get(ApiEndpoints.newArrivals);
      final data = (response.data as Map<String, dynamic>)['data'] as List;
      return data
          .map((e) => BookModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<PaginatedResponse<BookModel>> searchBooks({
    required String query,
    int page = 1,
    String? language,
    String? categoryId,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.searchBooks,
        queryParameters: {
          'q': query,
          'page': page,
          if (language != null) 'language': language,
          if (categoryId != null) 'category_id': categoryId,
        },
      );
      return _parsePaginatedBooks(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<BookModel> uploadBook({
    Uint8List? coverBytes,
    String? coverFileName,
    Uint8List? bookBytes,
    String? bookFileName,
    String? bookLink,
    required Map<String, dynamic> bookData,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      final Map<String, dynamic> fields = {...bookData};
      if (coverBytes != null) {
        final ext =
            (coverFileName ?? 'cover.jpg').split('.').last.toLowerCase();
        final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
        fields['cover_image'] = MultipartFile.fromBytes(
          coverBytes,
          filename: coverFileName ?? 'cover.jpg',
          contentType: MediaType.parse(mime),
        );
      }

      if (bookLink != null && bookLink.isNotEmpty) {
        // Use external link instead of file upload
        fields['book_url'] = bookLink;
      } else if (bookBytes != null && bookFileName != null) {
        final bookExt = bookFileName.split('.').last.toLowerCase();
        final bookMime = switch (bookExt) {
          'epub' => 'application/epub+zip',
          'docx' =>
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          _ => 'application/pdf',
        };
        fields['book_file'] = MultipartFile.fromBytes(
          bookBytes,
          filename: bookFileName,
          contentType: MediaType.parse(bookMime),
        );
      }

      final formData = FormData.fromMap(fields);

      final response = await _dio.post(
        ApiEndpoints.books,
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = (response.data as Map<String, dynamic>)['data'];
      return BookModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<BookModel> updateBook({
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
      final response = await _dio.patch(
        ApiEndpoints.bookUpdate(bookId),
        data: {
          if (title != null) 'title': title,
          if (titleKm != null) 'title_km': titleKm,
          if (author != null) 'author': author,
          if (description != null) 'description': description,
          if (descriptionKm != null) 'description_km': descriptionKm,
          if (publishYear != null) 'publication_year': publishYear,
          if (isPrivate != null) 'is_private': isPrivate,
        },
      );
      final data = (response.data as Map<String, dynamic>)['data'];
      return BookModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteBook(String bookId) async {
    try {
      await _dio.delete(ApiEndpoints.bookDelete(bookId));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<ReviewModel>> getReviews(String bookId) async {
    try {
      final response = await _dio.get(ApiEndpoints.bookReviews(bookId));
      final payload = _extractPayload(response.data);

      if (payload is List) {
        return payload
            .whereType<Map<String, dynamic>>()
            .map(ReviewModel.fromJson)
            .toList();
      }

      if (payload is Map<String, dynamic>) {
        return [ReviewModel.fromJson(payload)];
      }

      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ReviewModel> addReview({
    required String bookId,
    required int rating,
    String? title,
    String? body,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.bookReviews(bookId),
        data: {
          'rating': rating,
          if (title != null) 'title': title,
          if (body != null) 'body': body,
          if (body != null) 'comment': body,
        },
      );
      final payload = _extractPayload(response.data);

      if (payload is Map<String, dynamic>) {
        return ReviewModel.fromJson(payload);
      }
      if (payload is List &&
          payload.isNotEmpty &&
          payload.first is Map<String, dynamic>) {
        return ReviewModel.fromJson(payload.first as Map<String, dynamic>);
      }

      throw const ApiException(message: 'Invalid review response format');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> toggleFavorite(String bookId) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.toggleFavorite(bookId),
      );
      final data = response.data as Map<String, dynamic>;
      return data['is_favorited'] as bool? ?? false;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<ReviewModel>> getMyReviews() async {
    try {
      final response = await _dio.get(ApiEndpoints.myReviews);
      final payload = _extractPayload(response.data);

      if (payload is List) {
        return payload
            .whereType<Map<String, dynamic>>()
            .map(ReviewModel.fromJson)
            .toList();
      }

      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;
    if (e.error is NetworkException) return e.error as NetworkException;
    return ApiException(message: e.message ?? 'Unknown error');
  }
}
