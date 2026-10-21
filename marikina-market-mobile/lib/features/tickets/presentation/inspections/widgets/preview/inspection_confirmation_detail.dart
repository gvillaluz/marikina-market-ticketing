import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class InspectionConfirmationDetail extends StatelessWidget {
  final String label;
  final String value;
  const InspectionConfirmationDetail({
    required this.label,
    required this.value,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppTheme.inspectionCaptionStyle.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: AppTheme.inspectionTinyGap),
      Text(value, style: AppTheme.inspectionBodyStyle),
    ],
  );
}
