import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/book_model.dart';

class BookThumbnail extends StatelessWidget {
  final BookModel book;
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const BookThumbnail({
    super.key,
    required this.book,
    this.width = 90,
    this.height = 130,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(10);

    if (book.coverUrl == null || book.coverUrl!.isEmpty) {
      return _buildPlaceholder(radius);
    }

    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: book.coverUrl!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (_, __) => _shimmer(radius),
        errorWidget: (_, __, ___) => _buildPlaceholder(radius),
      ),
    );
  }

  Widget _shimmer(BorderRadius radius) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.surfaceAlt,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: radius,
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BorderRadius radius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: radius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.menu_book_rounded,
            color: AppColors.textLight,
            size: 28,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              book.title,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textLight,
                fontFamily: 'NotoSansKhmer',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
