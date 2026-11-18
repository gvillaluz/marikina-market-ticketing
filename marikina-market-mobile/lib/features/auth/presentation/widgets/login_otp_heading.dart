import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class LoginOtpHeading extends StatelessWidget {
  final String maskedEmail;

  const LoginOtpHeading({super.key, required this.maskedEmail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sign-in verification', style: AppTheme.authPageTitleStyle),
        const SizedBox(height: AppTheme.authSmallGap),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Enter the 6-digit code sent to '),
              TextSpan(
                text: maskedEmail,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.authVerificationTitleColor,
                ),
              ),
              const TextSpan(text: ' to finish logging in.'),
            ],
          ),
          textAlign: TextAlign.start,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.authVerificationBodyColor,
          ),
        ),
      ],
    );
  }
}
