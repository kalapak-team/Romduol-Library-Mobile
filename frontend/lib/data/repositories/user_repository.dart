import 'package:dartz/dartz.dart';

import '../../core/network/api_exception.dart';
import '../datasources/remote/user_remote_datasource.dart';
import '../models/user_model.dart';

class UserRepository {
  final UserRemoteDataSource _remote;

  UserRepository(this._remote);

  Future<Either<String, UserModel>> getUserByUsername(String username) async {
    try {
      return Right(await _remote.getUserByUsername(username));
    } on ApiException catch (e) {
      return Left(e.message);
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }

  Future<Either<String, bool>> toggleFollow(String userId) async {
    try {
      return Right(await _remote.toggleFollow(userId));
    } on ApiException catch (e) {
      return Left(e.message);
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }

  Future<Either<String, List<UserModel>>> getFollowing() async {
    try {
      return Right(await _remote.getFollowing());
    } on ApiException catch (e) {
      return Left(e.message);
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }

  Future<Either<String, List<UserModel>>> getUserFollowers(
      String username) async {
    try {
      return Right(await _remote.getUserFollowers(username));
    } on ApiException catch (e) {
      return Left(e.message);
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }

  Future<Either<String, List<UserModel>>> getUserFollowing(
      String username) async {
    try {
      return Right(await _remote.getUserFollowing(username));
    } on ApiException catch (e) {
      return Left(e.message);
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }
}
