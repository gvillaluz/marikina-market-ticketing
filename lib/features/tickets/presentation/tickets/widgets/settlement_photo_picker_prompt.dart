import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';

class SettlementPhotoPickerPrompt extends StatelessWidget {
  final String label;

  const SettlementPhotoPickerPrompt({required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'JPG, PNG · max 5 MB each',
          style: TextStyle(color: AppColors.mediumGrey, fontSize: 12),
        ),
      ],
    );
  }
}
