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
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'Filter by ticket status',
    initialValue: statusSelected?.value ?? '',
    position: PopupMenuPosition.under,
    borderRadius: AppTheme.ticketCardRadius,
    color: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: AppTheme.ticketCardRadius,
    ),
    onSelected: (value) =>
        onChange(value.isEmpty ? null : TicketStatus.fromValue(value)),
    itemBuilder: (context) => [
      for (final status in <TicketStatus?>[null, ...TicketStatus.values])
        PopupMenuItem<String>(
          value: status?.value ?? '',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                statusSelected == status ? Icons.check : null,
                size: AppTheme.ticketIconSize,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppTheme.ticketTinyGap),
              Flexible(
                child: Text(
                  status?.label ?? 'All statuses',
                  style: AppTheme.ticketBodyStyle,
                ),
              ),
            ],
          ),
        ),
    ],
    child: Ink(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppTheme.ticketCardRadius,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
        child: Padding(
          padding: AppTheme.ticketFilterPadding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_list, size: AppTheme.ticketIconSize),
              const SizedBox(width: AppTheme.ticketTinyGap),
              Flexible(
                child: Text(
                  statusSelected?.label ?? 'All statuses',
                  style: AppTheme.ticketCaptionStyle,
                ),
              ),
              const SizedBox(width: AppTheme.ticketTinyGap),
              Icon(Icons.expand_more, size: AppTheme.ticketIconSize),
            ],
          ),
        ),
      ),
    ),
  );
}
