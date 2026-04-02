import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../models/user_model.dart';

class UserRemoteDataSource {
  final Dio _dio = DioClient.instance;

  Future<UserModel> getUserByUsername(String username) async {
    try {
      final response = await _dio.get(ApiEndpoints.userProfile(username));
      final data = (response.data as Map<String, dynamic>)['data'];
      return UserModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> toggleFollow(String userId) async {
    try {
      final response = await _dio.post(ApiEndpoints.toggleFollow(userId));
      final data = response.data as Map<String, dynamic>;
      return data['is_following'] as bool;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<UserModel>> getFollowing() async {
    try {
      final response = await _dio.get(ApiEndpoints.myFollowing);
      final data = (response.data as Map<String, dynamic>)['data'] as List;
      return data
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<UserModel>> getUserFollowers(String username) async {
    try {
      final response = await _dio.get(ApiEndpoints.userFollowers(username));
      final data = (response.data as Map<String, dynamic>)['data'] as List;
      return data
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<UserModel>> getUserFollowing(String username) async {
    try {
      final response = await _dio.get(ApiEndpoints.userFollowingList(username));
      final data = (response.data as Map<String, dynamic>)['data'] as List;
      return data
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
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
