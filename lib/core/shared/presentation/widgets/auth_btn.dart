import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class AuthBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  const AuthBtn({
    required this.onPressed,
    required this.isLoading,
    required this.label,
    super.key,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading) ...[
            SizedBox.square(
              dimension: AppTheme.buttonIconSize,
              child: CircularProgressIndicator(
                value: MediaQuery.disableAnimationsOf(context) ? 0.75 : null,
                strokeWidth: AppTheme.buttonProgressStrokeWidth,
                color: Theme.of(context).colorScheme.primary,
                semanticsLabel: 'Loading',
                semanticsValue: 'In progress',
              ),
            ),
            const SizedBox(width: AppTheme.authSmallGap),
          ],
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ],
      ),
    ),
  );
}
