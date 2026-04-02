import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../models/user_model.dart';

class AuthRemoteDataSource {
  final Dio _dio = DioClient.instance;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String username,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.register,
        data: {
          'name': name,
          'username': username,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserModel> getMe() async {
    try {
      final response = await _dio.get(ApiEndpoints.me);
      final data = (response.data as Map<String, dynamic>)['data'];
      return UserModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post(ApiEndpoints.forgotPassword, data: {'email': email});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserModel> updateProfile({
    String? name,
    String? nameKm,
    String? bio,
    String? bioKm,
    String? language,
    List<int>? avatarBytes,
    String? avatarFileName,
  }) async {
    try {
      final formData = FormData();
      if (name != null) formData.fields.add(MapEntry('name', name));
      if (nameKm != null) formData.fields.add(MapEntry('name_km', nameKm));
      if (bio != null) formData.fields.add(MapEntry('bio', bio));
      if (bioKm != null) formData.fields.add(MapEntry('bio_km', bioKm));
      if (language != null) formData.fields.add(MapEntry('language', language));
      if (avatarBytes != null && avatarFileName != null) {
        final ext = avatarFileName.split('.').last.toLowerCase();
        final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
        formData.files.add(MapEntry(
          'avatar',
          MultipartFile.fromBytes(
            avatarBytes,
            filename: avatarFileName,
            contentType: MediaType.parse(mimeType),
          ),
        ));
      }
      final response = await _dio.post(
        ApiEndpoints.updateProfile,
        data: formData,
      );
      final data = (response.data as Map<String, dynamic>)['data'];
      return UserModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      await _dio.post(ApiEndpoints.changePassword, data: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPasswordConfirmation,
      });
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
