import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/remote/admin_remote_datasource.dart';
import '../../../data/models/book_model.dart';
import '../../../data/models/dashboard_stats_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(AdminRemoteDataSource());
});

final adminDashboardProvider =
    AsyncNotifierProvider<AdminDashboardNotifier, DashboardStats>(
  AdminDashboardNotifier.new,
);

class AdminDashboardNotifier extends AsyncNotifier<DashboardStats> {
  @override
  Future<DashboardStats> build() async {
    final repo = ref.read(adminRepositoryProvider);
    final result = await repo.getDashboardStats();
    return result.fold(
      (error) => throw Exception(error),
      (stats) => stats,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final repo = ref.read(adminRepositoryProvider);
    final result = await repo.getDashboardStats();
    state = result.fold(
      (error) => AsyncError(Exception(error), StackTrace.current),
      (stats) => AsyncData(stats),
    );
  }

  Future<String?> toggleRequireBookApproval(bool value) async {
    final repo = ref.read(adminRepositoryProvider);
    final result = await repo.updateSettings(requireBookApproval: value);
    return result.fold(
      (error) => error,
      (msg) {
        // Refresh dashboard to get updated setting
        refresh();
        return null;
      },
    );
  }
}

// ── Admin Books ───────────────────────────────────────────────────────────

final adminBooksProvider =
    AsyncNotifierProvider<AdminBooksNotifier, List<BookModel>>(
  AdminBooksNotifier.new,
);

class AdminBooksNotifier extends AsyncNotifier<List<BookModel>> {
  late final AdminRepository _repo;
  String _search = '';
  String _statusFilter = '';

  @override
  Future<List<BookModel>> build() async {
    _repo = ref.read(adminRepositoryProvider);
    return _fetchBooks();
  }

  Future<List<BookModel>> _fetchBooks() async {
    final result = await _repo.getBooks(
      search: _search.isEmpty ? null : _search,
      status: _statusFilter.isEmpty ? null : _statusFilter,
    );
    return result.fold(
      (error) => throw Exception(error),
      (books) => books,
    );
  }

  Future<void> search(String query) async {
    _search = query;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchBooks);
  }

  Future<void> filterByStatus(String status) async {
    _statusFilter = status;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchBooks);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchBooks);
  }

  Future<String?> approveBook(String id) async {
    final result = await _repo.approveBook(id);
    return result.fold(
      (error) => error,
      (msg) {
        _updateBookStatus(id, 'approved');
        return null;
      },
    );
  }

  Future<String?> rejectBook(String id, {String? reason}) async {
    final result = await _repo.rejectBook(id, reason: reason);
    return result.fold(
      (error) => error,
      (msg) {
        _updateBookStatus(id, 'rejected');
        return null;
      },
    );
  }

  Future<String?> featureBook(String id) async {
    final result = await _repo.featureBook(id);
    return result.fold(
      (error) => error,
      (msg) {
        _toggleBookFeatured(id);
        return null;
      },
    );
  }

  Future<String?> updateBook(String id, Map<String, dynamic> data) async {
    final result = await _repo.updateBook(id, data);
    return result.fold(
      (error) => error,
      (updated) {
        final current = state.valueOrNull;
        if (current != null) {
          state = AsyncData(
            current.map((b) => b.id == id ? updated : b).toList(),
          );
        }
        return null;
      },
    );
  }

  Future<String?> deleteBook(String id) async {
    final result = await _repo.deleteBook(id);
    return result.fold(
      (error) => error,
      (msg) {
        _removeBook(id);
        return null;
      },
    );
  }

  void _updateBookStatus(String id, String newStatus) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.map((b) {
        if (b.id == id) {
          return BookModel.fromJson({
            ...{
              'id': b.id,
              'user_id': b.userId,
              'category_id': b.categoryId,
              'title': b.title,
              'title_km': b.titleKm,
              'author': b.author,
              'author_km': b.authorKm,
              'description': b.description,
              'description_km': b.descriptionKm,
              'cover_url': b.coverUrl,
              'file_url': b.fileUrl,
              'file_type': b.fileType,
              'file_size_kb': b.fileSizeKb,
              'language': b.language,
              'isbn': b.isbn,
              'publisher': b.publisher,
              'publish_year': b.publishYear,
              'pages': b.pages,
              'status': newStatus,
              'is_featured': b.isFeatured,
              'download_count': b.downloadCount,
              'view_count': b.viewCount,
              'avg_rating': b.avgRating,
              'review_count': b.reviewCount,
              'created_at': b.createdAt,
            },
          });
        }
        return b;
      }).toList(),
    );
  }

  void _toggleBookFeatured(String id) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.map((b) {
        if (b.id == id) {
          return BookModel.fromJson({
            'id': b.id,
            'user_id': b.userId,
            'category_id': b.categoryId,
            'title': b.title,
            'title_km': b.titleKm,
            'author': b.author,
            'author_km': b.authorKm,
            'description': b.description,
            'description_km': b.descriptionKm,
            'cover_url': b.coverUrl,
            'file_url': b.fileUrl,
            'file_type': b.fileType,
            'file_size_kb': b.fileSizeKb,
            'language': b.language,
            'isbn': b.isbn,
            'publisher': b.publisher,
            'publish_year': b.publishYear,
            'pages': b.pages,
            'status': b.status,
            'is_featured': !b.isFeatured,
            'download_count': b.downloadCount,
            'view_count': b.viewCount,
            'avg_rating': b.avgRating,
            'review_count': b.reviewCount,
            'created_at': b.createdAt,
          });
        }
        return b;
      }).toList(),
    );
  }

  void _removeBook(String id) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.where((b) => b.id != id).toList());
  }
}

// ── Admin Users ───────────────────────────────────────────────────────────

final adminUsersProvider =
    AsyncNotifierProvider<AdminUsersNotifier, List<UserModel>>(
  AdminUsersNotifier.new,
);

class AdminUsersNotifier extends AsyncNotifier<List<UserModel>> {
  late final AdminRepository _repo;
  String _search = '';
  String _statusFilter = '';

  @override
  Future<List<UserModel>> build() async {
    _repo = ref.read(adminRepositoryProvider);
    return _fetchUsers();
  }

  Future<List<UserModel>> _fetchUsers() async {
    final result = await _repo.getUsers(
      search: _search.isEmpty ? null : _search,
      status: _statusFilter.isEmpty ? null : _statusFilter,
    );
    return result.fold(
      (error) => throw Exception(error),
      (users) => users,
    );
  }

  Future<void> search(String query) async {
    _search = query;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchUsers);
  }

  Future<void> filterByStatus(String status) async {
    _statusFilter = status;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchUsers);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchUsers);
  }

  Future<String?> banUser(String id) async {
    final result = await _repo.banUser(id);
    return result.fold(
      (error) => error,
      (msg) {
        _updateUserStatus(id, 'banned');
        return null;
      },
    );
  }

  Future<String?> unbanUser(String id) async {
    final result = await _repo.unbanUser(id);
    return result.fold(
      (error) => error,
      (msg) {
        _updateUserStatus(id, 'active');
        return null;
      },
    );
  }

  Future<String?> promoteUser(String id) async {
    final result = await _repo.promoteUser(id);
    return result.fold(
      (error) => error,
      (msg) {
        _updateUserRole(id, 'admin');
        return null;
      },
    );
  }

  Future<String?> deleteUser(String id) async {
    final result = await _repo.deleteUser(id);
    return result.fold(
      (error) => error,
      (msg) {
        _removeUser(id);
        return null;
      },
    );
  }

  void _updateUserStatus(String id, String newStatus) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.map((u) {
        if (u.id == id) {
          return UserModel.fromJson({...u.toJson(), 'status': newStatus});
        }
        return u;
      }).toList(),
    );
  }

  void _updateUserRole(String id, String newRole) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.map((u) {
        if (u.id == id) {
          return UserModel.fromJson({...u.toJson(), 'role': newRole});
        }
        return u;
      }).toList(),
    );
  }

  void _removeUser(String id) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.where((u) => u.id != id).toList());
  }
}
