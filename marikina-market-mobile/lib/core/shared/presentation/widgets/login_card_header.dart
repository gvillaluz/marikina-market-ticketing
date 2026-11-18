import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

/// The blue logo header of the login card. [opening] runs from 0 to 1 while
/// the logo and then the title fade in.
class LoginCardHeader extends StatelessWidget {
  final Animation<double> opening;
  const LoginCardHeader({required this.opening, super.key});

  @override
  Widget build(BuildContext context) {
    final titleOpacity = opening.drive(
      CurveTween(curve: AppTheme.authOpeningTitleInterval),
    );
    final titleColor = Theme.of(context).colorScheme.onPrimary;
    return Container(
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
            opacity: opening.drive(
              CurveTween(curve: AppTheme.authOpeningLogoInterval),
            ),
          ),
          const SizedBox(height: AppTheme.authSmallGap),
          AnimatedBuilder(
            animation: titleOpacity,
            builder: (context, _) => Text(
              'Marikina Public Market Inspection System',
              style: AppTheme.authHeaderTextStyle.copyWith(
                color: titleColor.withValues(alpha: titleOpacity.value),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
