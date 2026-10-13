import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class Filters extends StatelessWidget {
  final String filterOption;
  final ValueChanged<String> onChange;
  const Filters({
    required this.filterOption,
    required this.onChange,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppTheme.notificationSmallGap,
    runSpacing: AppTheme.notificationSmallGap,
    children: ['All', 'Unread']
        .map(
          (filter) => ChoiceChip(
            label: Text(filter),
            selected: filterOption == filter,
            materialTapTargetSize: MaterialTapTargetSize.padded,
            chipAnimationStyle: ChipAnimationStyle(
              selectAnimation: AnimationStyle(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : AppTheme.buttonAnimationDuration,
              ),
            ),
            onSelected: (selected) {
              if (selected) onChange(filter);
            },
          ),
        )
        .toList(),
  );
}
