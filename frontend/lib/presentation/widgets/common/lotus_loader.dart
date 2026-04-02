import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class LotusLoader extends StatelessWidget {
  final double size;

  const LotusLoader({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            // Use Lottie if available, else a CircularProgressIndicator
            child: _buildLoader(),
          ),
          const SizedBox(height: 12),
          Text(
            'loading'.tr(),
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildLoader() {
    return Lottie.asset(
      'assets/animations/lotus_loading.json',
      repeat: true,
      errorBuilder: (_, __, ___) => const CircularProgressIndicator(
        color: AppColors.primary,
        strokeWidth: 3,
      ),
    );
  }
}

class InlineLoader extends StatelessWidget {
  const InlineLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 3,
        ),
      ),
    );
  }
}
