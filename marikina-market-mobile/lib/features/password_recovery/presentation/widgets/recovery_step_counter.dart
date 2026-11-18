import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

/// "Step 2 of 4" with a thin progress bar, shown above the heading of each
/// forgot-password step.
class RecoveryStepCounter extends StatelessWidget {
  static const totalSteps = 4;

  final int step;
  const RecoveryStepCounter({required this.step, super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppTheme.authGap),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step $step of $totalSteps',
          style: const TextStyle(
            color: AppTheme.authVerificationBodyColor,
            fontSize: AppTheme.bodyFontSize,
          ),
        ),
        const SizedBox(height: AppTheme.authSmallGap),
        ExcludeSemantics(
          child: ClipRRect(
            borderRadius: AppTheme.authStepBarRadius,
            child: LinearProgressIndicator(
              value: step / totalSteps,
              minHeight: AppTheme.authStepBarHeight,
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: AppTheme.authStepTrackColor,
            ),
          ),
        ),
      ],
    ),
  );
}
