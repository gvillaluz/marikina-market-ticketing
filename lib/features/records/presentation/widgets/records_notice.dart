import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class RecordsNotice extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;
  const RecordsNotice({
    required this.message,
    this.onRetry,
    this.icon = Icons.info_outline,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: AppTheme.recordsPagePadding,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: AppTheme.inspectionSmallGap),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTheme.inspectionBodyStyle,
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
