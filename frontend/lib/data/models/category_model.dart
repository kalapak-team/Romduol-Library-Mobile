import 'package:equatable/equatable.dart';

class CategoryModel extends Equatable {
  final String id;
  final String name;
  final String? nameKm;
  final String slug;
  final String? icon;
  final String? colorHex;
  final String? description;
  final String? parentId;
  final int sortOrder;
  final int? bookCount;

  const CategoryModel({
    required this.id,
    required this.name,
    this.nameKm,
    required this.slug,
    this.icon,
    this.colorHex,
    this.description,
    this.parentId,
    required this.sortOrder,
    this.bookCount,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        nameKm: json['name_km'] as String?,
        slug: json['slug']?.toString() ?? '',
        icon: json['icon'] as String?,
        colorHex: json['color_hex'] as String?,
        description: json['description'] as String?,
        parentId: json['parent_id']?.toString(),
        sortOrder: json['sort_order'] as int? ?? 0,
        bookCount: json['book_count'] as int?,
      );

  @override
  List<Object?> get props => [id, slug];
}
