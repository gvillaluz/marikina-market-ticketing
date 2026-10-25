import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class ProcessLoadingOverlay extends StatelessWidget {
  final String message;
  const ProcessLoadingOverlay({required this.message, super.key});
  @override
  Widget build(BuildContext context) => Dialog(
    child: SingleChildScrollView(
      padding: AppTheme.inspectionCardPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: AppTheme.inspectionProcessingSize,
            child: CircularProgressIndicator(
              value: MediaQuery.disableAnimationsOf(context) ? 0.75 : null,
              semanticsLabel: 'Processing inspection',
            ),
          ),
          const SizedBox(height: AppTheme.inspectionSmallGap),
          Text(
            'Processing inspection',
            textAlign: TextAlign.center,
            style: AppTheme.inspectionHeadingStyle,
          ),
          const SizedBox(height: AppTheme.inspectionSmallGap),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTheme.inspectionBodyStyle,
          ),
        ],
      ),
    ),
  );
}
