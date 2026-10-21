import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class QrScannerStatus extends StatelessWidget {
  final String message;
  final bool isLoading;
  final VoidCallback? onRetry;
  const QrScannerStatus({
    required this.message,
    this.isLoading = false,
    this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight:
          MediaQuery.sizeOf(context).height *
          AppTheme.scannerStatusMaxHeightRatio,
    ),
    child: SingleChildScrollView(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: AppTheme.selectionSheetPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLoading)
                    SizedBox.square(
                      dimension: AppTheme.buttonIconSize,
                      child: CircularProgressIndicator(
                        value: MediaQuery.disableAnimationsOf(context)
                            ? 0.75
                            : null,
                        color: AppTheme.scannerForeground,
                        strokeWidth: AppTheme.buttonProgressStrokeWidth,
                        semanticsLabel: 'Checking vendor',
                      ),
                    )
                  else
                    const Icon(
                      Icons.qr_code_scanner,
                      color: AppTheme.scannerForeground,
                    ),
                  const SizedBox(width: AppTheme.inspectionSmallGap),
                  Expanded(
                    child: Text(
                      message,
                      style: AppTheme.inspectionBodyStyle.copyWith(
                        color: AppTheme.scannerForeground,
                      ),
                    ),
                  ),
                ],
              ),
              if (onRetry != null)
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.scannerForeground,
                  ),
                  label: const Text('Scan again'),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
