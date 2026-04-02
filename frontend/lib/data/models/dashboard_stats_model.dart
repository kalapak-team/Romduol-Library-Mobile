import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final UserStats users;
  final BookStats books;
  final int totalDownloads;
  final List<RecentUser> recentUsers;
  final List<RecentPendingBook> recentPendingBooks;
  final bool requireBookApproval;

  const DashboardStats({
    required this.users,
    required this.books,
    required this.totalDownloads,
    required this.recentUsers,
    required this.recentPendingBooks,
    required this.requireBookApproval,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final usersData = json['users'] as Map<String, dynamic>? ?? {};
    final booksData = json['books'] as Map<String, dynamic>? ?? {};
    final recentUsersList = json['recent_users'] as List<dynamic>? ?? [];
    final recentBooksList =
        json['recent_pending_books'] as List<dynamic>? ?? [];

    return DashboardStats(
      users: UserStats.fromJson(usersData),
      books: BookStats.fromJson(booksData),
      totalDownloads: (json['total_downloads'] as num?)?.toInt() ?? 0,
      recentUsers: recentUsersList
          .map((e) => RecentUser.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentPendingBooks: recentBooksList
          .map((e) => RecentPendingBook.fromJson(e as Map<String, dynamic>))
          .toList(),
      requireBookApproval: json['require_book_approval'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        users,
        books,
        totalDownloads,
        recentUsers,
        recentPendingBooks,
        requireBookApproval
      ];
}

class UserStats extends Equatable {
  final int total;
  final int active;
  final int banned;
  final int admins;

  const UserStats({
    required this.total,
    required this.active,
    required this.banned,
    required this.admins,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
        total: (json['total'] as num?)?.toInt() ?? 0,
        active: (json['active'] as num?)?.toInt() ?? 0,
        banned: (json['banned'] as num?)?.toInt() ?? 0,
        admins: (json['admins'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [total, active, banned, admins];
}

class BookStats extends Equatable {
  final int total;
  final int approved;
  final int pending;
  final int rejected;
  final int featured;

  const BookStats({
    required this.total,
    required this.approved,
    required this.pending,
    required this.rejected,
    required this.featured,
  });

  factory BookStats.fromJson(Map<String, dynamic> json) => BookStats(
        total: (json['total'] as num?)?.toInt() ?? 0,
        approved: (json['approved'] as num?)?.toInt() ?? 0,
        pending: (json['pending'] as num?)?.toInt() ?? 0,
        rejected: (json['rejected'] as num?)?.toInt() ?? 0,
        featured: (json['featured'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [total, approved, pending, rejected, featured];
}

class RecentUser extends Equatable {
  final String id;
  final String name;
  final String username;
  final String email;
  final String? avatarUrl;
  final String role;
  final String status;
  final DateTime createdAt;

  const RecentUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.avatarUrl,
    required this.role,
    required this.status,
    required this.createdAt,
  });

  factory RecentUser.fromJson(Map<String, dynamic> json) => RecentUser(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        username: json['username']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        avatarUrl: json['avatar_url'] as String?,
        role: json['role'] as String? ?? 'user',
        status: json['status'] as String? ?? 'active',
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );

  @override
  List<Object?> get props => [id];
}

class RecentPendingBook extends Equatable {
  final String id;
  final String title;
  final String? titleKm;
  final String? coverUrl;
  final String? uploaderName;
  final DateTime createdAt;

  const RecentPendingBook({
    required this.id,
    required this.title,
    this.titleKm,
    this.coverUrl,
    this.uploaderName,
    required this.createdAt,
  });

  factory RecentPendingBook.fromJson(Map<String, dynamic> json) {
    final uploader = json['uploader'] as Map<String, dynamic>?;
    return RecentPendingBook(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      titleKm: json['title_km'] as String?,
      coverUrl: json['cover_url'] as String?,
      uploaderName: uploader?['name']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id];
}
