import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class SelectionSheetMessage extends StatelessWidget {
  final String message;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onRetry;

  const SelectionSheetMessage({
    required this.message,
    this.icon = Icons.search_outlined,
    this.isLoading = false,
    this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: AppTheme.selectionSheetPadding,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox.square(
            dimension: AppTheme.inspectionProcessingSize,
            child: CircularProgressIndicator(
              value: MediaQuery.disableAnimationsOf(context) ? 0.75 : null,
              semanticsLabel: message,
            ),
          )
        else
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
