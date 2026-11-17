import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

/// One password rule: a ring that fills with a tick, and the rule in words.
class PasswordRuleLine extends StatelessWidget {
  final String label;
  final bool met;

  const PasswordRuleLine({required this.label, required this.met, super.key});

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppTheme.buttonAnimationDuration;
    final markColor = met ? AppTheme.authRuleMetColor : AppColors.mediumGrey;
    return Semantics(
      label: '${met ? 'Done' : 'Not yet'}: $label',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(top: AppTheme.authRuleGap),
        child: Row(
          children: [
            AnimatedContainer(
              duration: duration,
              width: AppTheme.authRuleMarkSize,
              height: AppTheme.authRuleMarkSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: met ? AppTheme.authRuleMetColor : Colors.transparent,
                border: Border.all(
                  color: markColor,
                  width: AppTheme.authRuleMarkBorderWidth,
                ),
              ),
              child: met
                  ? Icon(
                      Icons.check_rounded,
                      size: AppTheme.authRuleCheckSize,
                      color: Theme.of(context).colorScheme.surface,
                    )
                  : null,
            ),
            const SizedBox(width: AppTheme.authSmallGap),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: duration,
                style: AppTheme.authBodyStyle.copyWith(
                  color: met
                      ? AppTheme.authRuleMetColor
                      : AppTheme.authVerificationBodyColor,
                ),
                child: Text(label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
