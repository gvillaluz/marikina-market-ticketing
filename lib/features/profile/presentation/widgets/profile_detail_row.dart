import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/account_status.dart';

class ProfileDetailRow extends StatelessWidget {
  final String label;
  final String? value;
  final AccountStatus? status;
  const ProfileDetailRow({
    required this.label,
    this.value,
    this.status,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: AppTheme.profileDetailPadding,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final labelWidget = Text(
          label,
          style: AppTheme.profileCaptionStyle.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
        final active = status == AccountStatus.active;
        final Widget detail = status == null
            ? Text(
                value == null || value!.trim().isEmpty
                    ? 'Not provided'
                    : value!,
                style: AppTheme.profileBodyStyle,
                textAlign: TextAlign.end,
              )
            : Align(
                alignment: Alignment.centerRight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.profileStatusBackground(active),
                    borderRadius: AppTheme.controlRadius,
                  ),
                  child: Padding(
                    padding: AppTheme.profileStatusPadding,
                    child: Text(
                      status!.value,
                      style: AppTheme.profileBodyStyle.copyWith(
                        color: AppTheme.profileStatusColor(active),
                      ),
                    ),
                  ),
                ),
              );
        final largeText =
            MediaQuery.textScalerOf(
              context,
            ).scale(AppTheme.profileBodyStyle.fontSize!) >
            AppTheme.profileBodyStyle.fontSize! *
                AppTheme.profileHeaderMaxTextScale;
        if (constraints.maxWidth < AppTheme.profileDetailStackBreakpoint ||
            largeText) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              labelWidget,
              const SizedBox(height: AppTheme.profileSmallGap),
              detail,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: AppTheme.profileDetailLabelFlex, child: labelWidget),
            const SizedBox(width: AppTheme.profileSmallGap),
            Expanded(flex: AppTheme.profileDetailValueFlex, child: detail),
          ],
        );
      },
    ),
  );
}
