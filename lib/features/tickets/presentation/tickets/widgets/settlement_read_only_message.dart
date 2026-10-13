import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';

class SettlementReadOnlyMessage extends StatelessWidget {
  final String text;

  const SettlementReadOnlyMessage({required this.text, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(color: AppColors.mediumGrey, fontSize: 12),
        ),
      ),
    );
  }
}
