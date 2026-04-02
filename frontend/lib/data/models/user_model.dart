import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String? nameKm;
  final String username;
  final String email;
  final String? avatarUrl;
  final String? bio;
  final String? bioKm;
  final String role;
  final String status;
  final String? country;
  final String language;
  final int booksUploaded;
  final int booksDownloaded;
  final int followersCount;
  final int followingCount;
  final bool isFollowing;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    this.nameKm,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.bio,
    this.bioKm,
    required this.role,
    required this.status,
    this.country,
    required this.language,
    required this.booksUploaded,
    required this.booksDownloaded,
    required this.followersCount,
    required this.followingCount,
    required this.isFollowing,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isUser => role == 'user';
  bool get isActive => status == 'active';

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        nameKm: json['name_km'] as String?,
        username: json['username']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        avatarUrl: json['avatar_url'] as String?,
        bio: json['bio'] as String?,
        bioKm: json['bio_km'] as String?,
        role: json['role'] as String? ?? 'user',
        status: json['status'] as String? ?? 'active',
        country: json['country'] as String?,
        language: json['language'] as String? ?? 'km',
        booksUploaded: (json['books_uploaded'] as num?)?.toInt() ?? 0,
        booksDownloaded: (json['books_downloaded'] as num?)?.toInt() ?? 0,
        followersCount: (json['followers_count'] as num?)?.toInt() ?? 0,
        followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
        isFollowing: json['is_following'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'name_km': nameKm,
        'username': username,
        'email': email,
        'avatar_url': avatarUrl,
        'bio': bio,
        'bio_km': bioKm,
        'role': role,
        'status': status,
        'country': country,
        'language': language,
        'books_uploaded': booksUploaded,
        'books_downloaded': booksDownloaded,
        'followers_count': followersCount,
        'following_count': followingCount,
        'is_following': isFollowing,
        'created_at': createdAt.toIso8601String(),
      };

  UserModel copyWith({
    String? name,
    String? nameKm,
    String? avatarUrl,
    String? bio,
    String? bioKm,
    String? language,
    int? followersCount,
    int? followingCount,
    bool? isFollowing,
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        nameKm: nameKm ?? this.nameKm,
        username: username,
        email: email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        bio: bio ?? this.bio,
        bioKm: bioKm ?? this.bioKm,
        role: role,
        status: status,
        country: country,
        language: language ?? this.language,
        booksUploaded: booksUploaded,
        booksDownloaded: booksDownloaded,
        followersCount: followersCount ?? this.followersCount,
        followingCount: followingCount ?? this.followingCount,
        isFollowing: isFollowing ?? this.isFollowing,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, username, email, role, status];
}
