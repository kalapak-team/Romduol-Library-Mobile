import 'package:equatable/equatable.dart';
import 'category_model.dart';

class BookUploaderInfo extends Equatable {
  final String id;
  final String name;
  final String? nameKm;
  final String username;
  final String? avatarUrl;
  final String role;

  const BookUploaderInfo({
    required this.id,
    required this.name,
    this.nameKm,
    required this.username,
    this.avatarUrl,
    required this.role,
  });

  bool get isAdmin => role == 'admin';

  factory BookUploaderInfo.fromJson(Map<String, dynamic> json) =>
      BookUploaderInfo(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        nameKm: json['name_km'] as String?,
        username: json['username']?.toString() ?? '',
        avatarUrl: json['avatar_url'] as String?,
        role: json['role'] as String? ?? 'user',
      );

  @override
  List<Object?> get props => [id, username];
}

class BookModel extends Equatable {
  final String id;
  final String userId;
  final String? categoryId;
  final String title;
  final String? titleKm;
  final String author;
  final String? authorKm;
  final String? description;
  final String? descriptionKm;
  final String? coverUrl;
  final String fileUrl;
  final String fileType;
  final int? fileSizeKb;
  final String language;
  final String? isbn;
  final String? publisher;
  final int? publishYear;
  final int? pages;
  final String status;
  final bool isFeatured;
  final bool isPrivate;
  final int downloadCount;
  final int viewCount;
  final double avgRating;
  final int reviewCount;
  final bool? isFavorited;
  final CategoryModel? category;
  final BookUploaderInfo? uploader;
  final String createdAt;

  const BookModel({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.title,
    this.titleKm,
    required this.author,
    this.authorKm,
    this.description,
    this.descriptionKm,
    this.coverUrl,
    required this.fileUrl,
    required this.fileType,
    this.fileSizeKb,
    required this.language,
    this.isbn,
    this.publisher,
    this.publishYear,
    this.pages,
    required this.status,
    required this.isFeatured,
    this.isPrivate = false,
    required this.downloadCount,
    required this.viewCount,
    required this.avgRating,
    required this.reviewCount,
    this.isFavorited,
    this.category,
    this.uploader,
    required this.createdAt,
  });

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isLink => fileType == 'link';

  BookModel withFavorited(bool fav) => BookModel(
        id: id,
        userId: userId,
        categoryId: categoryId,
        title: title,
        titleKm: titleKm,
        author: author,
        authorKm: authorKm,
        description: description,
        descriptionKm: descriptionKm,
        coverUrl: coverUrl,
        fileUrl: fileUrl,
        fileType: fileType,
        fileSizeKb: fileSizeKb,
        language: language,
        isbn: isbn,
        publisher: publisher,
        publishYear: publishYear,
        pages: pages,
        status: status,
        isFeatured: isFeatured,
        isPrivate: isPrivate,
        downloadCount: downloadCount,
        viewCount: viewCount,
        avgRating: avgRating,
        reviewCount: reviewCount,
        isFavorited: fav,
        category: category,
        uploader: uploader,
        createdAt: createdAt,
      );

  factory BookModel.fromJson(Map<String, dynamic> json) => BookModel(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        categoryId: json['category_id']?.toString(),
        title: json['title']?.toString() ?? '',
        titleKm: json['title_km'] as String?,
        author: json['author']?.toString() ?? '',
        authorKm: json['author_km'] as String?,
        description: json['description'] as String?,
        descriptionKm: json['description_km'] as String?,
        coverUrl: json['cover_url'] as String?,
        fileUrl: json['file_url'] as String? ?? '',
        fileType: json['file_type'] as String? ?? 'pdf',
        fileSizeKb: (json['file_size_kb'] as num?)?.toInt(),
        language: json['language'] as String? ?? 'km',
        isbn: json['isbn'] as String?,
        publisher: json['publisher'] as String?,
        publishYear: (json['publish_year'] as num?)?.toInt(),
        pages: (json['pages'] as num?)?.toInt(),
        status: json['status'] as String? ?? 'pending',
        isFeatured: json['is_featured'] as bool? ?? false,
        isPrivate: json['is_private'] as bool? ?? false,
        downloadCount: (json['download_count'] as num?)?.toInt() ?? 0,
        viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
        avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
        isFavorited: json['is_favorited'] as bool?,
        category: json['category'] != null
            ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
            : null,
        uploader: json['uploader'] != null
            ? BookUploaderInfo.fromJson(
                json['uploader'] as Map<String, dynamic>)
            : null,
        createdAt: json['created_at'] as String? ?? '',
      );

  @override
  List<Object?> get props => [id, title, userId, status];
}
