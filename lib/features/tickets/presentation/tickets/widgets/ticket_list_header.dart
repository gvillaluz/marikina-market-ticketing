import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_filter_row.dart';

class TicketListHeader extends StatelessWidget {
  final TextEditingController searchController;
  final TicketStatus selectedStatus;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchSubmitted;
  final ValueChanged<TicketStatus> onStatusChanged;
  const TicketListHeader({
    required this.searchController,
    required this.selectedStatus,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onStatusChanged,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Tickets',
        style: AppTheme.ticketTitleStyle.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      const SizedBox(height: AppTheme.ticketTinyGap),
      Text(
        'Review issued tickets and settlement status.',
        style: AppTheme.ticketBodyStyle.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: AppTheme.ticketGap),
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: searchController,
        builder: (context, value, child) => TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          onSubmitted: (_) => onSearchSubmitted(),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'Search tickets',
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      searchController.clear();
                      onSearchSubmitted();
                    },
                    icon: const Icon(Icons.close),
                  ),
          ),
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
        ),
      ),
      const SizedBox(height: AppTheme.ticketSmallGap),
      TicketFilterRow(
        statusSelected: selectedStatus,
        onChange: onStatusChanged,
      ),
    ],
  );
}
