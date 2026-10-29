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
            Wrap(
              spacing: AppTheme.ticketTinyGap,
              runSpacing: AppTheme.ticketTinyGap,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'SYSTEM CONTROL:',
                  style: AppTheme.ticketCaptionStyle.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '#${ticketSummary.controlNumber}',
                  style: AppTheme.ticketHeadingStyle.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                TicketStatusBadge(status: ticketSummary.ticketStatus),
              ],
            ),
            Text(
              'Paper reference: ${ticketSummary.paperReference ?? 'Unavailable (legacy record)'}',
              style: AppTheme.ticketBodyStyle,
            ),
            Text(
              'Issue place: ${ticketSummary.issuePlace ?? 'Unavailable (legacy record)'}',
              style: AppTheme.ticketBodyStyle,
            ),
            const SizedBox(height: AppTheme.ticketSmallGap),
            Text(
              ticketSummary.businessName,
              style: AppTheme.ticketHeadingStyle,
            ),
            Text(
              [
                ticketSummary.marketSection,
                if (ticketSummary.stallNumber != null &&
                    ticketSummary.stallNumber!.trim().isNotEmpty)
                  ticketSummary.stallNumber!,
              ].join(' • '),
              style: AppTheme.ticketBodyStyle.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (ticketSummary.ordinance.isNotEmpty) ...[
              const SizedBox(height: AppTheme.ticketSmallGap),
              for (final ordinance in ticketSummary.ordinance)
                Text(ordinance, style: AppTheme.ticketBodyStyle),
            ],
            const Divider(),
            Text(
              DateTimeFormatter.getShortDateTime(ticketSummary.issuedAt),
              style: AppTheme.ticketBodyStyle,
            ),
            if (ticketSummary.ticketStatus == TicketStatus.overdue &&
                ticketSummary.overDueDate != null)
              Text(
                'Overdue: ${DateTimeFormatter.getDate(ticketSummary.overDueDate!)}',
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
