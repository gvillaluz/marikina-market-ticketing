import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? valueWidget;
  const DetailRow({
    required this.label,
    required this.value,
    this.valueWidget,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    final labelText = Text(
      label,
      style: AppTheme.inspectionCaptionStyle.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
    final valueContent =
        valueWidget ??
        Text(
          value,
          textAlign: TextAlign.right,
          style: AppTheme.inspectionBodyStyle,
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(flex: 2, child: labelText),
        const SizedBox(width: AppTheme.detailRowGap),
        Flexible(flex: 3, child: valueContent),
      ],
    );
  }
}
