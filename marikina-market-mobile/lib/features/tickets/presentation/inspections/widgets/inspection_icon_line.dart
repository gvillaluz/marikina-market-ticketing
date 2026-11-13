import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class InspectionIconLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const InspectionIconLine({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppTheme.inspectionIconSize, color: color),
        const SizedBox(width: AppTheme.inspectionTinyGap),
        Expanded(
          child: Text(
            text,
            style: AppTheme.inspectionBodyStyle.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
