import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

enum BookBadgeType { newBook, featured, khmer, approved, pending, rejected }

class BookBadge extends StatelessWidget {
  final BookBadgeType type;

  const BookBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final config = _config[type]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: config.$1,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        config.$2,
        style: AppTextStyles.labelSmall.copyWith(
          color: config.$3,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static const _config = {
    BookBadgeType.newBook: (Color(0xFF4CAF82), 'ថ្មី', Colors.white),
    BookBadgeType.featured: (AppColors.accent, 'ពិសេស', AppColors.textDark),
    BookBadgeType.khmer: (AppColors.primary, 'ខ្មែរ', Colors.white),
    BookBadgeType.approved: (Color(0xFF4CAF82), 'Approved', Colors.white),
    BookBadgeType.pending: (AppColors.accent, 'Pending', AppColors.textDark),
    BookBadgeType.rejected: (AppColors.error, 'Rejected', Colors.white),
  };
}
