import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';

class TicketFilterRow extends StatelessWidget {
  final TicketStatus? statusSelected;
  final ValueChanged<TicketStatus?> onChange;
  const TicketFilterRow({
    required this.statusSelected,
    required this.onChange,
    super.key,
  });
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    // Recreate the field when the parent changes its controlled selection.
    key: ValueKey(statusSelected),
    initialValue: statusSelected?.value ?? '',
    isExpanded: true,
    style: AppTheme.ticketBodyStyle.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
    ),
    decoration: const InputDecoration(labelText: 'Status', isDense: true),
    items: [
      const DropdownMenuItem(value: '', child: Text('All statuses')),
      for (final status in TicketStatus.values)
        DropdownMenuItem(value: status.value, child: Text(status.label)),
    ],
    onChanged: (value) {
      if (value != null) {
        onChange(value.isEmpty ? null : TicketStatus.fromValue(value));
      }
    },
  );
}
