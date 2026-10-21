import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';

class TicketFilterRow extends StatelessWidget {
  final TicketStatus statusSelected;
  final ValueChanged<TicketStatus> onChange;
  const TicketFilterRow({
    required this.statusSelected,
    required this.onChange,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppTheme.ticketTinyGap,
    runSpacing: AppTheme.ticketTinyGap,
    children: TicketStatus.values
        .map(
          (status) => ChoiceChip(
            label: Text(status.value),
            selected: statusSelected == status,
            materialTapTargetSize: MaterialTapTargetSize.padded,
            chipAnimationStyle: ChipAnimationStyle(
              selectAnimation: AnimationStyle(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : AppTheme.buttonAnimationDuration,
              ),
            ),
            onSelected: (selected) {
              if (selected) onChange(status);
            },
          ),
        )
        .toList(),
  );
}
