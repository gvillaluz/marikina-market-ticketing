import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

// Registered / Unregistered, in the same style as the Ticket / Warning choice.
class VendorKindToggle extends StatelessWidget {
  final bool isUnregistered;
  final ValueChanged<bool> onChange;

  const VendorKindToggle({
    required this.isUnregistered,
    required this.onChange,
    super.key,
  });

  Widget _option(BuildContext context, String label, bool unregistered) {
    final colors = Theme.of(context).colorScheme;
    final selected = isUnregistered == unregistered;
    return Expanded(
      child: Semantics(
        selected: selected,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: selected ? colors.primary : colors.surface,
            foregroundColor: selected ? colors.onPrimary : colors.primary,
            padding: AppTheme.inspectionBadgePadding,
            textStyle: AppTheme.inspectionHeadingStyle,
            animationDuration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : AppTheme.buttonAnimationDuration,
          ),
          onPressed: () {
            if (!selected) onChange(unregistered);
          },
          child: Text(label, textAlign: TextAlign.center),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Row(
    spacing: AppTheme.inspectionTinyGap,
    children: [
      _option(context, 'Registered', false),
      _option(context, 'Unregistered', true),
    ],
  );
}
