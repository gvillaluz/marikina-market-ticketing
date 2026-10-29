import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class AppOutlinedBtn extends StatelessWidget {
  final String label;
  final IconData iconData;
  final VoidCallback? onPressed;
  final Color foregroundColor;
  final Color backgroundColor;
  final bool isLoading;

  const AppOutlinedBtn({
    super.key,
    required this.label,
    required this.iconData,
    required this.onPressed,
    required this.foregroundColor,
    required this.backgroundColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : backgroundColor.withValues(alpha: 0.5),
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)
              : foregroundColor,
        ),
        side: WidgetStateProperty.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.disabled)
                ? Theme.of(context).colorScheme.outlineVariant
                : foregroundColor,
          ),
        ),
      ),
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox.square(
              dimension: AppTheme.buttonIconSize,
              child: CircularProgressIndicator(
                value: MediaQuery.disableAnimationsOf(context) ? 0.75 : null,
                strokeWidth: AppTheme.buttonProgressStrokeWidth,
                semanticsLabel: 'Loading',
                color: foregroundColor,
              ),
            )
          : Icon(iconData),
      label: Text(label, textAlign: TextAlign.center),
    ),
  );
}
