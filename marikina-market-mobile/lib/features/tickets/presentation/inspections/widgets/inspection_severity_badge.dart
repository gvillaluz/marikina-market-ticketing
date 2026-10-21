import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class InspectionSeverityBadge extends StatelessWidget {
  final Severity severity;
  const InspectionSeverityBadge({required this.severity, super.key});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppTheme.inspectionSeverityBackground(severity.value),
      borderRadius: AppTheme.controlRadius,
    ),
    child: Padding(
      padding: AppTheme.inspectionBadgePadding,
      child: Text(
        severity.value,
        style: AppTheme.inspectionCaptionStyle.copyWith(
          color: AppTheme.inspectionSeverityColor(severity.value),
        ),
      ),
    ),
  );
}
