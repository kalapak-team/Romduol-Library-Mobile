import 'package:dartz/dartz.dart';

import '../../core/network/api_exception.dart';
import '../datasources/remote/admin_remote_datasource.dart';
import '../models/book_model.dart';
import '../models/dashboard_stats_model.dart';
import '../models/user_model.dart';

class AdminRepository {
  final AdminRemoteDataSource _remote;

  AdminRepository(this._remote);

  String _formatApiError(ApiException e) {
    final errors = e.errors;
    if (errors != null && errors.isNotEmpty) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) return value.first.toString();
        if (value is String && value.isNotEmpty) return value;
      }
    }
    return e.message;
  }

  Future<Either<String, DashboardStats>> getDashboardStats() async {
    try {
      final stats = await _remote.getDashboardStats();
      return Right(stats);
    } on ApiException catch (e) {
      return Left(_formatApiError(e));
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }

  // ── Books ─────────────────────────────────────────────────────────────

  Future<Either<String, List<BookModel>>> getBooks({
    String? search,
    String? status,
    int page = 1,
  }) async {
    try {
      final books =
          await _remote.getBooks(search: search, status: status, page: page);
      return Right(books);
    } on ApiException catch (e) {
      return Left(_formatApiError(e));
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }

  Future<Either<String, String>> approveBook(String id) async {
    try {
      final msg = await _remote.approveBook(id);
      return Right(msg);
    } on ApiException catch (e) {
      return Left(_formatApiError(e));
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }

  Future<Either<String, String>> rejectBook(String id, {String? reason}) async {
    try {
      final msg = await _remote.rejectBook(id, reason: reason);
      return Right(msg);
    } on ApiException catch (e) {
      return Left(_formatApiError(e));
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }

  Future<Either<String, String>> featureBook(String id) async {
    try {
      final msg = await _remote.featureBook(id);
      return Right(msg);
    } on ApiException catch (e) {
      return Left(_formatApiError(e));
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }

  Future<Either<String, BookModel>> updateBook(
      String id, Map<String, dynamic> data) async {
    try {
      final book = await _remote.updateBook(id, data);
      return Right(book);
    } on ApiException catch (e) {
      return Left(_formatApiError(e));
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }

  Future<Either<String, String>> deleteBook(String id) async {
    try {
      final msg = await _remote.deleteBook(id);
      return Right(msg);
    } on ApiException catch (e) {
      return Left(_formatApiError(e));
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }

  // ── Users ─────────────────────────────────────────────────────────────

  Future<Either<String, List<UserModel>>> getUsers({
    String? search,
    String? status,
    int page = 1,
  }) async {
    try {
      final users =
          await _remote.getUsers(search: search, status: status, page: page);
      return Right(users);
    } on ApiException catch (e) {
      return Left(_formatApiError(e));
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }

  Future<Either<String, String>> banUser(String id) async {
    try {
      final msg = await _remote.banUser(id);
      return Right(msg);
    } on ApiException catch (e) {
      return Left(_formatApiError(e));
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }

  Future<Either<String, String>> unbanUser(String id) async {
    try {
      final msg = await _remote.unbanUser(id);
      return Right(msg);
    } on ApiException catch (e) {
      return Left(_formatApiError(e));
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }

  Future<Either<String, String>> promoteUser(String id) async {
    try {
      final msg = await _remote.promoteUser(id);
      return Right(msg);
    } on ApiException catch (e) {
      return Left(_formatApiError(e));
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }

  Future<Either<String, String>> deleteUser(String id) async {
    try {
      final msg = await _remote.deleteUser(id);
      return Right(msg);
    } on ApiException catch (e) {
      return Left(_formatApiError(e));
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }

  // ── Settings ──────────────────────────────────────────────────────────

  Future<Either<String, Map<String, dynamic>>> getSettings() async {
    try {
      final settings = await _remote.getSettings();
      return Right(settings);
    } on ApiException catch (e) {
      return Left(_formatApiError(e));
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }

  Future<Either<String, String>> updateSettings({
    required bool requireBookApproval,
  }) async {
    try {
      final msg = await _remote.updateSettings(
        requireBookApproval: requireBookApproval,
      );
      return Right(msg);
    } on ApiException catch (e) {
      return Left(_formatApiError(e));
    } on NetworkException catch (e) {
      return Left(e.message);
    }
  }
}
