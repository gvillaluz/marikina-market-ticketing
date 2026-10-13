import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/form_type_option.dart';

class InspectionTypeToggle extends StatelessWidget {
  final ViolationType selected;
  final ValueChanged<ViolationType> onChange;
  final bool isEnabled;
  const InspectionTypeToggle({
    required this.selected,
    required this.onChange,
    required this.isEnabled,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Row(
    spacing: AppTheme.inspectionTinyGap,
    children: ViolationType.values
        .map(
          (type) => Expanded(
            child: FormTypeOption(
              selectedType: selected,
              formType: type,
              onChange: onChange,
              isEnabled: isEnabled,
            ),
          ),
        )
        .toList(),
  );
}
