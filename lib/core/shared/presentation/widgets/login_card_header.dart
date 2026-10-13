import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class LoginCardHeader extends StatelessWidget {
  const LoginCardHeader({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: AppTheme.authCardPadding,
    decoration: BoxDecoration(
      borderRadius: AppTheme.authHeaderRadius,
      color: Theme.of(context).colorScheme.primary,
    ),
    child: Column(
      children: [
        Image.asset(
          'assets/logo/org_logo.png',
          height: AppTheme.authHeaderLogoSize,
          width: AppTheme.authHeaderLogoSize,
        ),
        const SizedBox(height: AppTheme.authSmallGap),
        Text(
          'Marikina Public Market Inspection System',
          style: AppTheme.authHeadingStyle.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
