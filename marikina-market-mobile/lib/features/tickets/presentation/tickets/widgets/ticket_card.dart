import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/core/utils/date_formatter_util.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_summary.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_status_badge.dart';

class TicketCard extends StatelessWidget {
  final TicketSummary ticketSummary;
  const TicketCard({required this.ticketSummary, super.key});
  void _open(BuildContext context) => context.pushNamed(
    Routes.ticketDetailName,
    pathParameters: {'ticketId': ticketSummary.ticketId.toString()},
  );
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: AppTheme.ticketCardRadius,
      side: BorderSide(
        color: ticketSummary.ticketStatus == TicketStatus.overdue
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.outlineVariant,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => _open(context),
      child: Padding(
        padding: AppTheme.ticketCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CONTROL NO.',
              style: AppTheme.ticketCaptionStyle.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTheme.ticketTinyGap),
            Text(
              '#${ticketSummary.controlNumber}',
              style: AppTheme.ticketHeadingStyle.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppTheme.ticketSmallGap),
            TicketStatusBadge(status: ticketSummary.ticketStatus),
            const SizedBox(height: AppTheme.ticketSmallGap),
            Text(
              ticketSummary.businessName,
              style: AppTheme.ticketHeadingStyle,
            ),
            Text(
              '${ticketSummary.marketSection} • ${ticketSummary.stallNumber}',
              style: AppTheme.ticketBodyStyle.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(),
            Text(
              DateTimeFormatter.getShortDateTime(ticketSummary.issuedAt),
              style: AppTheme.ticketBodyStyle,
            ),
            if (ticketSummary.ticketStatus == TicketStatus.overdue)
              Text(
                'Overdue: ${DateTimeFormatter.getDate(ticketSummary.overDueDate)}',
                style: AppTheme.ticketBodyStyle.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _open(context),
                child: const Text('View Details'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
