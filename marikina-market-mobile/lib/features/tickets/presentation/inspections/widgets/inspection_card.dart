import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/utils/date_formatter_util.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/inspection_ticket_summary.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/inspection_severity_badge.dart';

class InspectionCard extends StatelessWidget {
  final InspectionTicketSummary ticketSummary;
  const InspectionCard({super.key, required this.ticketSummary});

  void _openDetails(BuildContext context) => context.pushNamed(
    Routes.ticketDetailName,
    pathParameters: {'ticketId': ticketSummary.ticketId.toString()},
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final overdue = ticketSummary.status == TicketStatus.overdue;
    final stall = ticketSummary.stallNumber;
    final location = [
      ticketSummary.marketSection,
      if (stall != null && stall.trim().isNotEmpty) stall,
      '${ticketSummary.vendorLastName}, ${ticketSummary.vendorFirstName}',
    ].join(' • ');
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.inspectionCardRadius,
        side: BorderSide(color: overdue ? colors.error : colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetails(context),
        child: Padding(
          padding: AppTheme.inspectionCardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppTheme.inspectionSmallGap,
                runSpacing: AppTheme.inspectionTinyGap,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    ticketSummary.ticketType.value,
                    style: AppTheme.inspectionHeadingStyle.copyWith(
                      color: colors.primary,
                    ),
                  ),
                  if (ticketSummary.severity != null)
                    InspectionSeverityBadge(severity: ticketSummary.severity!),
                ],
              ),
              const SizedBox(height: AppTheme.inspectionSmallGap),
              Text(
                ticketSummary.businessName,
                style: AppTheme.inspectionHeadingStyle.copyWith(
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: AppTheme.inspectionTinyGap),
              Text(
                location,
                style: AppTheme.inspectionBodyStyle.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppTheme.inspectionSmallGap),
              ...ticketSummary.ordinance.map(
                (ordinance) => Text(
                  ordinance,
                  style: AppTheme.inspectionBodyStyle.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
              const Divider(),
              Wrap(
                spacing: AppTheme.inspectionTinyGap,
                runSpacing: AppTheme.inspectionTinyGap,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: AppTheme.inspectionIconSize,
                    color: colors.onSurfaceVariant,
                  ),
                  Text(
                    DateTimeFormatter.getShortDateTime(ticketSummary.issuedAt),
                    style: AppTheme.inspectionBodyStyle.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _openDetails(context),
                  child: const Text('View Details'),
                ),
              ),
              if (overdue)
                Text(
                  ticketSummary.overDueDate == null
                      ? 'Overdue'
                      : 'Overdue: ${DateTimeFormatter.getDate(ticketSummary.overDueDate!)}',
                  style: AppTheme.inspectionBodyStyle.copyWith(
                    color: colors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
