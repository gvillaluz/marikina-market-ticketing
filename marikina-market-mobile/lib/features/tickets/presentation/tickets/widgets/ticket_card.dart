import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/core/utils/date_formatter_util.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_summary.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/inspection_icon_line.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_status_badge.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/unregistered_vendor.dart';

class TicketCard extends StatefulWidget {
  final TicketSummary ticketSummary;
  final bool expanded;
  final VoidCallback onToggle;
  const TicketCard({
    required this.ticketSummary,
    required this.expanded,
    required this.onToggle,
    super.key,
  });

  @override
  State<TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<TicketCard> {
  static const _shownOrdinanceCount = 1;

  bool _pressed = false;

  TicketSummary get ticketSummary => widget.ticketSummary;

  void _openDetails(BuildContext context) => context.pushNamed(
    Routes.ticketDetailName,
    pathParameters: {'ticketId': ticketSummary.ticketId.toString()},
  );

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.disableAnimationsOf(context);
    final colors = Theme.of(context).colorScheme;
    final overdue = ticketSummary.ticketStatus == TicketStatus.overdue;
    final section = ticketSummary.isUnregistered
        ? ticketSummary.marketSection
        : ticketSummary.businessSnapshot?.marketSectionName;
    final stall = ticketSummary.isUnregistered
        ? ticketSummary.stallNumber
        : ticketSummary.businessSnapshot?.stallNumber;
    final location = [
      if (section != null && section.trim().isNotEmpty) section,
      if (stall != null && stall.trim().isNotEmpty) 'Stall $stall',
    ].join(' • ');
    final shownOrdinances = ticketSummary.ordinance.take(_shownOrdinanceCount);
    final hiddenOrdinances =
        ticketSummary.ordinance.length - shownOrdinances.length;
    return AnimatedScale(
      scale: _pressed && animate ? AppTheme.ticketCardPressedScale : 1,
      duration: AppTheme.ticketCardPressDuration,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.ticketCardRadius,
          side: BorderSide(
            color: overdue ? colors.error : colors.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onToggle,
          onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
          child: Padding(
            padding: AppTheme.ticketCardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: AppTheme.ticketSmallGap,
                    runSpacing: AppTheme.ticketTinyGap,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'CONTROL NUMBER:',
                            style: AppTheme.ticketCaptionStyle.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            ticketSummary.paperReference ??
                                'Unavailable (legacy record)',
                            style: AppTheme.ticketHeadingStyle.copyWith(
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                      TicketStatusBadge(status: ticketSummary.ticketStatus),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.ticketSmallGap),
                Text(
                  ticketSummary.isUnregistered
                      ? unregisteredVendorLabel
                      : (ticketSummary.businessSnapshot?.businessName ??
                            'Historical business details unavailable.'),
                  style: AppTheme.ticketHeadingStyle.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: AppTheme.ticketTinyGap),
                if (location.isNotEmpty)
                  InspectionIconLine(
                    icon: Icons.place_outlined,
                    text: location,
                  ),
                InspectionIconLine(
                  icon: Icons.person_outline,
                  text:
                      ticketSummary.paperViolatorName ??
                      'Unconfirmed (legacy record)',
                ),
                const SizedBox(height: AppTheme.ticketSmallGap),
                ...shownOrdinances.map(
                  (ordinance) => Text(
                    ordinance,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.ticketBodyStyle.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ),
                if (hiddenOrdinances > 0)
                  Text(
                    '+$hiddenOrdinances more ordinance${hiddenOrdinances == 1 ? '' : 's'}',
                    style: AppTheme.ticketBodyStyle.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const Divider(),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: AppTheme.ticketIconSize,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppTheme.ticketTinyGap),
                    Expanded(
                      child: Text(
                        DateTimeFormatter.getShortDateTime(
                          ticketSummary.issuedAt,
                        ),
                        style: AppTheme.ticketBodyStyle.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: animate
                      ? AppTheme.ticketCardExpandDuration
                      : Duration.zero,
                  alignment: Alignment.topCenter,
                  child: widget.expanded
                      ? Padding(
                          padding: const EdgeInsets.only(
                            top: AppTheme.ticketTinyGap,
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
                if (overdue && ticketSummary.overDueDate != null)
                  Text(
                    'Overdue: ${DateTimeFormatter.getDate(ticketSummary.overDueDate!)}',
                    style: AppTheme.ticketBodyStyle.copyWith(
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
