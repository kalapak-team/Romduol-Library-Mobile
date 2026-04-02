import 'package:dartz/dartz.dart';

import '../../core/network/api_exception.dart';
import '../../core/storage/secure_storage.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepository {
  final AuthRemoteDataSource _remote;

  AuthRepository(this._remote);

  String _extractToken(Map<String, dynamic> result) {
    final token = result['access_token'] ?? result['token'];
    if (token == null) {
      throw const ApiException(
          message: 'Login token is missing in API response.');
    }
    return token.toString();
  }

  Map<String, dynamic> _extractUserData(Map<String, dynamic> result) {
    final data = result['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
          message: 'User data is missing in API response.');
    }
    return data;
  }

  String _formatApiError(ApiException e) {
    final errors = e.errors;
    if (errors != null && errors.isNotEmpty) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
        if (value is String && value.isNotEmpty) {
          return value;
        }
      }
    }
    return e.message;
  }

  Future<Either<String, UserModel>> login(String email, String password) async {
    try {
      final result = await _remote.login(email, password);
      final token = _extractToken(result);
      final userData = _extractUserData(result);
      final user = UserModel.fromJson(userData);
      await SecureStorage.saveToken(token);
      await SecureStorage.saveUserId(user.id);
      await SecureStorage.saveUserRole(user.role);
      return Right(user);
    } on ApiException catch (e) {
      return Left(_formatApiError(e));
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }

  Future<Either<String, UserModel>> register({
    required String name,
    required String username,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final result = await _remote.register(
        name: name,
        username: username,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      final token = _extractToken(result);
      final userData = _extractUserData(result);
      final user = UserModel.fromJson(userData);
      await SecureStorage.saveToken(token);
      await SecureStorage.saveUserId(user.id);
      await SecureStorage.saveUserRole(user.role);
      return Right(user);
    } on ApiException catch (e) {
      return Left(_formatApiError(e));
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }

  Future<void> logout() async {
    try {
      await _remote.logout();
    } finally {
      await SecureStorage.clearAll();
    }
  }

  Future<Either<String, UserModel>> getMe() async {
    try {
      final user = await _remote.getMe();
      return Right(user);
    } on ApiException catch (e) {
      return Left(_formatApiError(e));
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await SecureStorage.getToken();
    return token != null;
  }

  Future<Either<String, UserModel>> updateProfile({
    String? name,
    String? nameKm,
    String? bio,
    String? bioKm,
    String? language,
    List<int>? avatarBytes,
    String? avatarFileName,
  }) async {
    try {
      final user = await _remote.updateProfile(
        name: name,
        nameKm: nameKm,
        bio: bio,
        bioKm: bioKm,
        language: language,
        avatarBytes: avatarBytes,
        avatarFileName: avatarFileName,
      );
      return Right(user);
    } on ApiException catch (e) {
      return Left(_formatApiError(e));
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }

  Future<Either<String, void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      await _remote.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        newPasswordConfirmation: newPasswordConfirmation,
      );
      return const Right(null);
    } on ApiException catch (e) {
      return Left(_formatApiError(e));
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }
}
