import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class AuthErrorNotice extends StatelessWidget {
  final String message;
  const AuthErrorNotice({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: AppTheme.authErrorPadding,
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: AppTheme.controlRadius,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              color: colors.onErrorContainer,
              size: AppTheme.authErrorIconSize,
            ),
            const SizedBox(width: AppTheme.authSmallGap),
            Expanded(
              child: Text(
                message.trim().isEmpty
                    ? 'Something went wrong. Please try again.'
                    : message,
                style: AppTheme.authBodyStyle.copyWith(
                  color: colors.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
