import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';

class FormTypeOption extends StatelessWidget {
  final ViolationType selectedType;
  final ViolationType formType;
  final ValueChanged<ViolationType> onChange;
  final bool? isEnabled;
  const FormTypeOption({
    required this.selectedType,
    required this.formType,
    required this.onChange,
    this.isEnabled,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selected = selectedType == formType;
    return Semantics(
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
        onPressed: isEnabled == false
            ? null
            : () {
                if (!selected) onChange(formType);
              },
        child: Text(formType.value, textAlign: TextAlign.center),
      ),
    );
  }
}
