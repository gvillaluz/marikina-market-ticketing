import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class ProfileUnavailable extends StatelessWidget {
  final String message;
  const ProfileUnavailable({required this.message, super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: SingleChildScrollView(
        padding: AppTheme.profilePagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_off_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppTheme.profileSmallGap),
            Text('Profile unavailable', style: AppTheme.profileHeadingStyle),
            const SizedBox(height: AppTheme.profileSmallGap),
            Text(
              message.trim().isEmpty
                  ? 'Please sign in again to view your profile.'
                  : message,
              textAlign: TextAlign.center,
              style: AppTheme.profileBodyStyle,
            ),
          ],
        ),
      ),
    ),
  );
}
