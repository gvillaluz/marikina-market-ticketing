import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

// A small caption with its value underneath, used in a person history card.
class PersonHistoryDetail extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;
  const PersonHistoryDetail({
    required this.label,
    required this.value,
    this.valueStyle,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppTheme.ticketCaptionStyle.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      Text(value, style: valueStyle ?? AppTheme.ticketBodyStyle),
    ],
  );
}
