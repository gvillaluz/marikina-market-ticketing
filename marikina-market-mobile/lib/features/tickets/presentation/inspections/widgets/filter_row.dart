import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';

class FilterRow extends StatelessWidget {
  final ViolationType? typeSelected;
  final ValueChanged<ViolationType?> onChange;
  const FilterRow({
    super.key,
    required this.typeSelected,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.recordsFilterBackground,
        borderRadius: AppTheme.controlRadius,
      ),
      child: Padding(
        padding: AppTheme.recordsFilterPadding,
        child: Row(
          children: [
            for (final type in <ViolationType?>[null, ...ViolationType.values])
              Expanded(
                child: TextButton(
                  onPressed: () => onChange(type),
                  style: TextButton.styleFrom(
                    backgroundColor: typeSelected == type
                        ? colors.primary
                        : null,
                    foregroundColor: typeSelected == type
                        ? colors.onPrimary
                        : colors.primary,
                    padding: AppTheme.recordsFilterButtonPadding,
                    textStyle: AppTheme.recordsBodyStyle,
                  ),
                  child: Semantics(
                    selected: typeSelected == type,
                    child: Text(
                      type == null
                          ? 'All'
                          : type == ViolationType.warning
                          ? 'Warnings'
                          : 'Tickets',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
