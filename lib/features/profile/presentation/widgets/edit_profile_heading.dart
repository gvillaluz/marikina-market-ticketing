import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class EditProfileHeading extends StatelessWidget {
  const EditProfileHeading({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Update your account information',
        style: AppTheme.profileEditTitleStyle.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      const SizedBox(height: AppTheme.profileSmallGap),
      Text(
        'Keep your personal and contact details up to date.',
        style: AppTheme.detailSubtitleStyle.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      const SizedBox(height: AppTheme.profileGap),
    ],
  );
}
