import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class TicketNotice extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;
  const TicketNotice({
    required this.title,
    required this.message,
    required this.icon,
    this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: AppTheme.ticketCardPadding,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: AppTheme.ticketCardRadius,
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: onRetry == null
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: AppTheme.ticketSmallGap),
        Text(title, style: AppTheme.ticketHeadingStyle),
        const SizedBox(height: AppTheme.ticketTinyGap),
        Text(
          message,
          style: AppTheme.ticketBodyStyle.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (onRetry != null)
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
      ],
    ),
  );
}
