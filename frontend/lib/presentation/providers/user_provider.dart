import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/user_remote_datasource.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';

final userRemoteDatasourceProvider = Provider((_) => UserRemoteDataSource());

final userRepositoryProvider = Provider(
  (ref) => UserRepository(ref.read(userRemoteDatasourceProvider)),
);

final userProfileProvider =
    FutureProvider.family.autoDispose<UserModel, String>((ref, username) async {
  final repo = ref.read(userRepositoryProvider);
  final result = await repo.getUserByUsername(username);
  return result.fold((e) => throw Exception(e), (user) => user);
});

final myFollowingProvider =
    FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final repo = ref.read(userRepositoryProvider);
  final result = await repo.getFollowing();
  return result.fold((e) => throw Exception(e), (users) => users);
});

final userFollowersProvider = FutureProvider.family
    .autoDispose<List<UserModel>, String>((ref, username) async {
  final repo = ref.read(userRepositoryProvider);
  final result = await repo.getUserFollowers(username);
  return result.fold((e) => throw Exception(e), (users) => users);
});

final userFollowingProvider = FutureProvider.family
    .autoDispose<List<UserModel>, String>((ref, username) async {
  final repo = ref.read(userRepositoryProvider);
  final result = await repo.getUserFollowing(username);
  return result.fold((e) => throw Exception(e), (users) => users);
});
