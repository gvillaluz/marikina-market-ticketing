import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';

class SettlementImageLoadError extends StatelessWidget {
  const SettlementImageLoadError({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      color: AppColors.primaryLight,
      alignment: Alignment.center,
      child: const Text(
        'Unable to load photo.',
        style: TextStyle(color: AppColors.mediumGrey),
      ),
    );
  }
}
