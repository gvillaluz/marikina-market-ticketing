import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_primary_btn.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class LogoutConfirmationDialog extends StatelessWidget {
  const LogoutConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      semanticLabel: 'Confirm logout',
      scrollable: true,
      constraints: const BoxConstraints(
        maxWidth: AppTheme.profileDialogMaxWidth,
      ),
      insetPadding: AppTheme.profileDialogInset,
      icon: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: .08),
            borderRadius: AppTheme.controlRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.profileSmallGap),
            child: Icon(
              Icons.logout_rounded,
              size: AppTheme.profileDialogIconSize,
              color: colors.primary,
            ),
          ),
        ),
      ),
      title: Text(
        'Log out?',
        textAlign: TextAlign.center,
        style: AppTheme.detailTitleStyle.copyWith(color: colors.onSurface),
      ),
      content: Text(
        'You will need to sign in again to access your account.',
        textAlign: TextAlign.center,
        style: AppTheme.bodyTextStyle.copyWith(color: colors.onSurfaceVariant),
      ),
      actionsPadding: AppTheme.profileDialogPadding,
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppPrimaryButton(
              label: 'Log Out',
              iconData: Icons.logout,
              onPressed: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: AppTheme.profileSmallGap),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }
}
