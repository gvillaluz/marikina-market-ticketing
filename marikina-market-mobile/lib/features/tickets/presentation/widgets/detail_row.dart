import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const DetailRow({required this.label, required this.value, super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < AppTheme.detailRowStackBreakpoint) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label),
            const SizedBox(height: AppTheme.detailRowGap),
            Text(value),
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: AppTheme.detailRowGap),
          Expanded(child: Text(value, textAlign: TextAlign.right)),
        ],
      );
    },
  );
}
