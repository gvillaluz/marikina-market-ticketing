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
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: AppTheme.profileSmallGap),
      Text(
        'Keep your personal and contact details up to date.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: AppTheme.profileGap),
    ],
  );
}
