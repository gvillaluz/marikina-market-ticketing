import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class RecordDetailRow extends StatelessWidget {
  final String label, value;
  const RecordDetailRow({required this.label, required this.value, super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: AppTheme.ticketItemPadding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: AppTheme.inspectionCaptionStyle.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value.trim().isEmpty ? 'Not provided' : value,
          style: AppTheme.inspectionBodyStyle,
        ),
      ],
    ),
  );
}
