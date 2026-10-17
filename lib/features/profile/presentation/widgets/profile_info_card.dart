import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class ProfileInfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const ProfileInfoCard({
    required this.title,
    required this.children,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: AppTheme.profileCardDecoration(context),
    padding: const EdgeInsets.symmetric(vertical: AppTheme.profileSmallGap),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: AppTheme.profileInfoHeadingPadding,
          child: Text(
            title,
            style: AppTheme.sectionHeadingStyle.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...children,
      ],
    ),
  );
}
