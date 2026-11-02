import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class NotificationSkeletonCard extends StatelessWidget {
  const NotificationSkeletonCard({super.key});

  Widget _line(
    BuildContext context,
    TextStyle style, {
    double widthFactor = 1,
  }) => FractionallySizedBox(
    widthFactor: widthFactor,
    alignment: Alignment.centerLeft,
    child: SizedBox(
      height:
          MediaQuery.textScalerOf(context).scale(style.fontSize!) *
          (style.height ?? 1.4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          height: MediaQuery.textScalerOf(context).scale(style.fontSize!),
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.skeletonColor(context),
              borderRadius: AppTheme.skeletonTextRadius,
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final textScale =
          MediaQuery.textScalerOf(context).scale(AppTheme.bodyFontSize) /
          AppTheme.bodyFontSize;
      final effectiveWidth = constraints.maxWidth / textScale;
      final compact = effectiveWidth < AppTheme.detailRowStackBreakpoint;
      final bodyLines = compact ? 3 : 2;
      return DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.vendorNotificationUnreadBackground,
          borderRadius: AppTheme.vendorNotificationCardRadius,
          border: Border.all(color: AppTheme.vendorNotificationBorder),
        ),
        child: Padding(
          padding: AppTheme.vendorNotificationCardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox.square(
                dimension: AppTheme.vendorNotificationIconSize,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.skeletonColor(context),
                    borderRadius: AppTheme.skeletonTextRadius,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.vendorNotificationIconGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _line(
                      context,
                      AppTheme.vendorNotificationHeadingStyle,
                      widthFactor: .85,
                    ),
                    if (compact)
                      _line(
                        context,
                        AppTheme.vendorNotificationHeadingStyle,
                        widthFactor: .45,
                      ),
                    const SizedBox(height: AppTheme.vendorNotificationTextGap),
                    for (var line = 0; line < bodyLines; line++)
                      _line(
                        context,
                        AppTheme.notificationBodyStyle,
                        widthFactor: line == bodyLines - 1 ? .7 : 1,
                      ),
                    const SizedBox(height: AppTheme.vendorNotificationTextGap),
                    _line(
                      context,
                      AppTheme.notificationCaptionStyle,
                      widthFactor: .65,
                    ),
                    if (effectiveWidth <
                        AppTheme.notificationSkeletonTimestampWrapWidth)
                      _line(
                        context,
                        AppTheme.notificationCaptionStyle,
                        widthFactor: .35,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
