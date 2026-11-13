import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/utils/date_formatter_util.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/inspection_ticket_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/inspection_icon_line.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/inspection_severity_badge.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/unregistered_vendor.dart';

class InspectionCard extends StatefulWidget {
  final InspectionTicketSummary ticketSummary;
  final bool expanded;
  final VoidCallback onToggle;
  const InspectionCard({
    super.key,
    required this.ticketSummary,
    required this.expanded,
    required this.onToggle,
  });

  @override
  State<InspectionCard> createState() => _InspectionCardState();
}

class _InspectionCardState extends State<InspectionCard> {
  static const _shownOrdinanceCount = 1;

  bool _pressed = false;

  InspectionTicketSummary get ticketSummary => widget.ticketSummary;

  void _openDetails(BuildContext context) => context.pushNamed(
    Routes.ticketDetailName,
    pathParameters: {'ticketId': ticketSummary.ticketId.toString()},
  );

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.disableAnimationsOf(context);
    final colors = Theme.of(context).colorScheme;
    final overdue = ticketSummary.status == TicketStatus.overdue;
    final fromSnapshot =
        ticketSummary.ticketType == ViolationType.ticket &&
        !ticketSummary.isUnregistered;
    final section = fromSnapshot
        ? ticketSummary.businessSnapshot?.marketSectionName
        : ticketSummary.marketSection;
    final stall = fromSnapshot
        ? ticketSummary.businessSnapshot?.stallNumber
        : ticketSummary.stallNumber;
    final location = [
      if (section != null && section.trim().isNotEmpty) section,
      if (stall != null && stall.trim().isNotEmpty) 'Stall $stall',
    ].join(' • ');
    final person = ticketSummary.ticketType == ViolationType.ticket
        ? (ticketSummary.paperViolatorName ?? 'Unconfirmed (legacy record)')
        : (ticketSummary.personFullName ?? 'Unconfirmed (legacy record)');
    final shownOrdinances = ticketSummary.ordinance.take(_shownOrdinanceCount);
    final hiddenOrdinances =
        ticketSummary.ordinance.length - shownOrdinances.length;
    return AnimatedScale(
      scale: _pressed && animate ? AppTheme.inspectionCardPressedScale : 1,
      duration: AppTheme.inspectionCardPressDuration,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.inspectionCardRadius,
          side: BorderSide(
            color: overdue ? colors.error : colors.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onToggle,
          onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
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
                      InspectionSeverityBadge(
                        severity: ticketSummary.severity!,
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.inspectionSmallGap),
                Text(
                  ticketSummary.isUnregistered
                      ? unregisteredVendorLabel
                      : (ticketSummary.ticketType == ViolationType.ticket
                            ? (ticketSummary.businessSnapshot?.businessName ??
                                  'Historical business details unavailable.')
                            : ticketSummary.businessName!),
                  style: AppTheme.inspectionHeadingStyle.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: AppTheme.inspectionTinyGap),
                if (location.isNotEmpty)
                  InspectionIconLine(
                    icon: Icons.place_outlined,
                    text: location,
                  ),
                InspectionIconLine(icon: Icons.person_outline, text: person),
                const SizedBox(height: AppTheme.inspectionSmallGap),
                ...shownOrdinances.map(
                  (ordinance) => Text(
                    ordinance,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.inspectionBodyStyle.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ),
                if (hiddenOrdinances > 0)
                  Text(
                    '+$hiddenOrdinances more ordinance${hiddenOrdinances == 1 ? '' : 's'}',
                    style: AppTheme.inspectionBodyStyle.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const Divider(),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: AppTheme.inspectionIconSize,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppTheme.inspectionTinyGap),
                    Expanded(
                      child: Text(
                        DateTimeFormatter.getShortDateTime(
                          ticketSummary.issuedAt,
                        ),
                        style: AppTheme.inspectionBodyStyle.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: animate
                      ? AppTheme.inspectionCardExpandDuration
                      : Duration.zero,
                  alignment: Alignment.topCenter,
                  child: widget.expanded
                      ? Padding(
                          padding: const EdgeInsets.only(
                            top: AppTheme.inspectionTinyGap,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonal(
                              onPressed: () => _openDetails(context),
                              child: const Text('View Details'),
                            ),
                          ),
                        )
                      : const SizedBox(width: double.infinity),
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
      ),
    );
  }
}
