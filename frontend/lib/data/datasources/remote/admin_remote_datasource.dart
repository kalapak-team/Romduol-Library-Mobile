import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../models/book_model.dart';
import '../../models/dashboard_stats_model.dart';
import '../../models/user_model.dart';

class AdminRemoteDataSource {
  final Dio _dio = DioClient.instance;

  Future<DashboardStats> getDashboardStats() async {
    try {
      final response = await _dio.get(ApiEndpoints.adminDashboard);
      return DashboardStats.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Books ─────────────────────────────────────────────────────────────

  Future<List<BookModel>> getBooks({
    String? search,
    String? status,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;

      final response = await _dio.get(
        ApiEndpoints.adminBooks,
        queryParameters: queryParams,
      );
      final data = response.data as Map<String, dynamic>;
      final list = data['data'] as List<dynamic>;
      return list
          .map((e) => BookModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<String> approveBook(String id) async {
    try {
      final response = await _dio.post(ApiEndpoints.adminApproveBook(id));
      return (response.data as Map<String, dynamic>)['message'] as String? ??
          'Book approved.';
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<String> rejectBook(String id, {String? reason}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.adminRejectBook(id),
        data: reason != null ? {'reason': reason} : null,
      );
      return (response.data as Map<String, dynamic>)['message'] as String? ??
          'Book rejected.';
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<String> featureBook(String id) async {
    try {
      final response = await _dio.post(ApiEndpoints.adminFeatureBook(id));
      return (response.data as Map<String, dynamic>)['message'] as String? ??
          'Book featured.';
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<BookModel> updateBook(String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.put(ApiEndpoints.adminUpdateBook(id), data: data);
      final body = (response.data as Map<String, dynamic>)['data'];
      return BookModel.fromJson(body as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<String> deleteBook(String id) async {
    try {
      final response = await _dio.delete(ApiEndpoints.adminDeleteBook(id));
      return (response.data as Map<String, dynamic>)['message'] as String? ??
          'Book deleted.';
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Users ─────────────────────────────────────────────────────────────

  Future<List<UserModel>> getUsers(
      {String? search, String? status, int page = 1}) async {
    try {
      final queryParams = <String, dynamic>{'page': page};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;

      final response = await _dio.get(
        ApiEndpoints.adminUsers,
        queryParameters: queryParams,
      );
      final data = response.data as Map<String, dynamic>;
      final list = data['data'] as List<dynamic>;
      return list
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<String> banUser(String id) async {
    try {
      final response = await _dio.post(ApiEndpoints.adminBanUser(id));
      return (response.data as Map<String, dynamic>)['message'] as String? ??
          'User banned.';
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<String> unbanUser(String id) async {
    try {
      final response = await _dio.post(ApiEndpoints.adminUnbanUser(id));
      return (response.data as Map<String, dynamic>)['message'] as String? ??
          'User unbanned.';
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<String> promoteUser(String id) async {
    try {
      final response = await _dio.post(ApiEndpoints.adminPromoteUser(id));
      return (response.data as Map<String, dynamic>)['message'] as String? ??
          'User promoted.';
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<String> deleteUser(String id) async {
    try {
      final response = await _dio.delete('${ApiEndpoints.adminUsers}/$id');
      return (response.data as Map<String, dynamic>)['message'] as String? ??
          'User deleted.';
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Settings ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await _dio.get(ApiEndpoints.adminSettings);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<String> updateSettings({required bool requireBookApproval}) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.adminSettings,
        data: {'require_book_approval': requireBookApproval},
      );
      return (response.data as Map<String, dynamic>)['message'] as String? ??
          'Settings updated.';
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
