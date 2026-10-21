import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class NotificationSkeletonCard extends StatelessWidget {
  final bool isVendor;
  const NotificationSkeletonCard({this.isVendor = false, super.key});

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
      final colors = Theme.of(context).colorScheme;
      final icon = SizedBox.square(
        dimension: isVendor
            ? AppTheme.vendorNotificationIconSize
            : AppTheme.notificationStatusIconSize,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.skeletonColor(context),
            borderRadius: AppTheme.skeletonTextRadius,
          ),
        ),
      );
      final bodyLines = compact ? 3 : 2;
      final body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isVendor) ...[
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
          ] else
            Wrap(
              spacing: AppTheme.notificationSmallGap,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                icon,
                SizedBox(
                  width: AppTheme.notificationSkeletonStatusWidth,
                  child: _line(context, AppTheme.notificationCaptionStyle),
                ),
              ],
            ),
          SizedBox(
            height: isVendor
                ? AppTheme.vendorNotificationTextGap
                : AppTheme.notificationSmallGap,
          ),
          for (var line = 0; line < bodyLines; line++)
            _line(
              context,
              AppTheme.notificationBodyStyle,
              widthFactor: line == bodyLines - 1 ? .7 : 1,
            ),
          SizedBox(
            height: isVendor
                ? AppTheme.vendorNotificationTextGap
                : AppTheme.notificationSmallGap,
          ),
          _line(context, AppTheme.notificationCaptionStyle, widthFactor: .65),
          if (effectiveWidth < AppTheme.notificationSkeletonTimestampWrapWidth)
            _line(context, AppTheme.notificationCaptionStyle, widthFactor: .35),
          if (!isVendor)
            Align(
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: .35,
                child: _line(context, AppTheme.notificationCaptionStyle),
              ),
            ),
        ],
      );
      return DecoratedBox(
        decoration: BoxDecoration(
          color: isVendor
              ? AppTheme.vendorNotificationUnreadBackground
              : colors.surface,
          borderRadius: isVendor
              ? AppTheme.vendorNotificationCardRadius
              : AppTheme.notificationCardRadius,
          border: isVendor
              ? Border.all(color: AppTheme.vendorNotificationBorder)
              : null,
        ),
        child: Padding(
          padding: isVendor
              ? AppTheme.vendorNotificationCardPadding
              : AppTheme.notificationCardPadding,
          child: isVendor
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    icon,
                    const SizedBox(width: AppTheme.vendorNotificationIconGap),
                    Expanded(child: body),
                  ],
                )
              : body,
        ),
      );
    },
  );
}
