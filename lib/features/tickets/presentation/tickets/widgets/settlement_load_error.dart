import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';

class SettlementLoadError extends StatelessWidget {
  final VoidCallback onRetry;

  const SettlementLoadError({required this.onRetry, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Unable to load settlement details.',
          style: TextStyle(color: AppColors.mediumGrey),
        ),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    );
  }
}
