import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class AppPrimaryButton extends StatelessWidget {
  final String label;
  final IconData iconData;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.iconData,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox.square(
              dimension: AppTheme.buttonIconSize,
              child: CircularProgressIndicator(
                value: MediaQuery.disableAnimationsOf(context) ? 0.75 : null,
                strokeWidth: AppTheme.buttonProgressStrokeWidth,
                semanticsLabel: 'Loading',
                semanticsValue: 'In progress',
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : Icon(iconData),
      label: Text(label, textAlign: TextAlign.center),
    ),
  );
}
