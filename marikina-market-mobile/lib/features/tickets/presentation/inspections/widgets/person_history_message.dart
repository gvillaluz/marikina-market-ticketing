import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_primary_btn.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

// The empty and error states of the person history: an icon, a short heading,
// the message, and an optional Retry button.
class PersonHistoryMessage extends StatelessWidget {
  final IconData iconData;
  final String title;
  final String message;
  final bool isError;
  final VoidCallback? onRetry;
  const PersonHistoryMessage({
    required this.iconData,
    required this.title,
    required this.message,
    this.isError = false,
    this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = isError ? colors.error : colors.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.ticketGap),
      child: Column(
        children: [
          Icon(iconData, size: AppTheme.dashboardIconSize * 2, color: color),
          const SizedBox(height: AppTheme.ticketSmallGap),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTheme.ticketHeadingStyle,
          ),
          const SizedBox(height: AppTheme.ticketTinyGap),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTheme.ticketBodyStyle.copyWith(color: color),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppTheme.ticketGap),
            AppPrimaryButton(
              label: 'Retry',
              iconData: Icons.refresh,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}
