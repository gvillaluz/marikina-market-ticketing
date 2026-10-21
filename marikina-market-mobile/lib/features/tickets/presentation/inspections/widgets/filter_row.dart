import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';

class FilterRow extends StatelessWidget {
  final ViolationType typeSelected;
  final ValueChanged<ViolationType> onChange;
  const FilterRow({
    super.key,
    required this.typeSelected,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Filter by type',
        style: AppTheme.inspectionCaptionStyle.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: AppTheme.inspectionTinyGap),
      Wrap(
        spacing: AppTheme.inspectionTinyGap,
        runSpacing: AppTheme.inspectionTinyGap,
        children: ViolationType.values
            .map(
              (type) => ChoiceChip(
                label: Text(type.value),
                selected: typeSelected == type,
                chipAnimationStyle: ChipAnimationStyle(
                  selectAnimation: AnimationStyle(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : AppTheme.buttonAnimationDuration,
                  ),
                ),
                materialTapTargetSize: MaterialTapTargetSize.padded,
                onSelected: (selected) {
                  if (selected) onChange(type);
                },
              ),
            )
            .toList(),
      ),
    ],
  );
}
