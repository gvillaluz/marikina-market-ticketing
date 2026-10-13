import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class ProfileDetailItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData iconData;
  const ProfileDetailItem({
    required this.label,
    required this.value,
    required this.iconData,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppTheme.profileSmallGap,
        runSpacing: AppTheme.profileSmallGap,
        children: [
          Icon(
            iconData,
            size: AppTheme.buttonIconSize,
            color: Theme.of(context).colorScheme.primary,
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.profileCaptionStyle.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppTheme.profileCompactGap),
      Text(
        value,
        textAlign: TextAlign.center,
        style: AppTheme.profileBodyStyle.copyWith(fontWeight: FontWeight.w600),
      ),
    ],
  );
}
