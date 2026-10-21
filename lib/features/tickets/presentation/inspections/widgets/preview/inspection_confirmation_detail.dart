import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class InspectionConfirmationDetail extends StatelessWidget {
  final String label;
  final String value;
  final Widget? valueWidget;
  const InspectionConfirmationDetail({
    required this.label,
    this.value = '',
    this.valueWidget,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Flexible(
        flex: 2,
        child: Text(
          label,
          style: AppTheme.inspectionCaptionStyle.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      const SizedBox(width: AppTheme.detailRowGap),
      Flexible(
        flex: 3,
        child:
            valueWidget ??
            Text(
              value,
              textAlign: TextAlign.right,
              style: AppTheme.inspectionBodyStyle,
            ),
      ),
    ],
  );
}
