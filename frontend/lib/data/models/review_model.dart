import 'package:equatable/equatable.dart';
import 'user_model.dart';

class ReviewBookInfo {
  final String id;
  final String title;
  final String? titleKm;
  final String? coverUrl;
  final String author;
  final String fileType;

  const ReviewBookInfo({
    required this.id,
    required this.title,
    this.titleKm,
    this.coverUrl,
    required this.author,
    required this.fileType,
  });

  factory ReviewBookInfo.fromJson(Map<String, dynamic> json) => ReviewBookInfo(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        titleKm: json['title_km'] as String?,
        coverUrl: json['cover_url'] as String?,
        author: json['author']?.toString() ?? '',
        fileType: json['file_type'] as String? ?? 'pdf',
      );
}

class ReviewModel extends Equatable {
  final String id;
  final String bookId;
  final String userId;
  final int rating;
  final String? title;
  final String? body;
  final bool isHidden;
  final String createdAt;
  final UserModel? user;
  final ReviewBookInfo? book;

  const ReviewModel({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.rating,
    this.title,
    this.body,
    required this.isHidden,
    required this.createdAt,
    this.user,
    this.book,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: json['id']?.toString() ?? '',
        bookId: json['book_id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        rating: (json['rating'] as num?)?.toInt() ?? 0,
        title: json['title'] as String?,
        body: (json['body'] ?? json['comment']) as String?,
        isHidden: json['is_hidden'] as bool? ?? false,
        createdAt: json['created_at'] as String? ?? '',
        user: json['user'] is Map<String, dynamic>
            ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
            : null,
        book: json['book'] is Map<String, dynamic>
            ? ReviewBookInfo.fromJson(json['book'] as Map<String, dynamic>)
            : null,
      );

  @override
  List<Object?> get props => [id, bookId, userId, rating];
}
