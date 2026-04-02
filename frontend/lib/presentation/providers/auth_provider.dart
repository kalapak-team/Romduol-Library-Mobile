import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

// Repository providers
final authRemoteDatasourceProvider = Provider((_) => AuthRemoteDataSource());

final authRepositoryProvider = Provider(
  (ref) => AuthRepository(ref.read(authRemoteDatasourceProvider)),
);

// Auth state: holds the current logged-in user (null = guest)
final authStateProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    final repo = ref.read(authRepositoryProvider);
    if (await repo.isLoggedIn()) {
      final result = await repo.getMe();
      return result.fold((_) => null, (user) => user);
    }
    return null;
  }

  Future<String?> login(String email, String password) async {
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.login(email, password);
    return result.fold(
      (error) {
        return error;
      },
      (user) {
        state = AsyncData(user);
        return null;
      },
    );
  }

  Future<String?> register({
    required String name,
    required String username,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.register(
      name: name,
      username: username,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
    return result.fold(
      (error) {
        return error;
      },
      (user) {
        state = AsyncData(user);
        return null;
      },
    );
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AsyncData(null);
  }

  void updateUser(UserModel user) => state = AsyncData(user);

  Future<String?> updateProfile({
    String? name,
    String? nameKm,
    String? bio,
    String? bioKm,
    String? language,
    List<int>? avatarBytes,
    String? avatarFileName,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.updateProfile(
      name: name,
      nameKm: nameKm,
      bio: bio,
      bioKm: bioKm,
      language: language,
      avatarBytes: avatarBytes,
      avatarFileName: avatarFileName,
    );
    return result.fold(
      (error) => error,
      (user) {
        state = AsyncData(user);
        return null;
      },
    );
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      newPasswordConfirmation: newPasswordConfirmation,
    );
    return result.fold(
      (error) => error,
      (_) => null,
    );
  }
}
