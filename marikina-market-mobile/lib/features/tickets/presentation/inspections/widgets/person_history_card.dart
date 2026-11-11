import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/utils/date_formatter_util.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/person_ticket_history.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/unregistered_vendor.dart';
import 'person_history_detail.dart';

// One past citation of a person: control number and status on top, then the
// business, the violation, when and where it was issued, and the cash amounts.
class PersonHistoryCard extends StatelessWidget {
  final PersonTicketHistory ticket;
  const PersonHistoryCard({required this.ticket, super.key});

  static final _money = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

  Widget _status(String status) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppTheme.ticketStatusBackground(status),
      borderRadius: AppTheme.controlRadius,
    ),
    child: Padding(
      padding: AppTheme.ticketBadgePadding,
      child: Text(
        status,
        style: AppTheme.ticketCaptionStyle.copyWith(
          color: AppTheme.ticketStatusColor(status),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final owed = ticket.outstandingCashFine > 0;
    final details = [
      PersonHistoryDetail(
        label: 'Issued',
        value: DateTimeFormatter.getShortDateTime(ticket.issuedAt),
      ),
      PersonHistoryDetail(label: 'Officer', value: ticket.enforcerName),
      PersonHistoryDetail(
        label: 'Issue place',
        value: ticket.issuePlace ?? 'Unavailable (legacy record)',
      ),
      PersonHistoryDetail(
        label: 'Recorded violator',
        value: ticket.paperViolatorName ?? 'Unconfirmed',
      ),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.ticketSmallGap),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppTheme.ticketCardRadius,
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Padding(
          padding: AppTheme.selectionSheetPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: PersonHistoryDetail(
                      label: 'Control number',
                      value:
                          ticket.paperReference ??
                          'Unavailable (legacy record)',
                      valueStyle: AppTheme.ticketHeadingStyle.copyWith(
                        color: colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.ticketSmallGap),
                  _status(ticket.status ?? 'Unknown'),
                ],
              ),
              const SizedBox(height: AppTheme.ticketSmallGap),
              Text(
                ticket.isUnregistered
                    ? unregisteredVendorLabel
                    : ticket.businessSnapshot?.businessName ??
                          'Historical business details unavailable.',
                style: AppTheme.ticketHeadingStyle,
              ),
              if (ticket.ordinances.isNotEmpty)
                Text(
                  ticket.ordinances.join('; '),
                  style: AppTheme.ticketBodyStyle.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              const Divider(height: AppTheme.ticketGap),
              LayoutBuilder(
                builder: (context, box) {
                  final twoColumns =
                      box.maxWidth >= AppTheme.ticketPaperFieldBreakpoint;
                  final width = twoColumns
                      ? (box.maxWidth - AppTheme.ticketSmallGap) / 2
                      : box.maxWidth;
                  return Wrap(
                    spacing: AppTheme.ticketSmallGap,
                    runSpacing: AppTheme.ticketSmallGap,
                    children: [
                      for (final detail in details)
                        SizedBox(width: width, child: detail),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppTheme.ticketSmallGap),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: AppTheme.controlRadius,
                ),
                child: Padding(
                  padding: AppTheme.selectionCardPadding,
                  child: Row(
                    children: [
                      Expanded(
                        child: PersonHistoryDetail(
                          label: 'Assessed cash',
                          value: ticket.assessedCashFine == null
                              ? 'Not cash'
                              : _money.format(ticket.assessedCashFine),
                          valueStyle: AppTheme.ticketHeadingStyle,
                        ),
                      ),
                      Expanded(
                        child: PersonHistoryDetail(
                          label: 'Outstanding cash',
                          value: _money.format(ticket.outstandingCashFine),
                          valueStyle: AppTheme.ticketHeadingStyle.copyWith(
                            color: owed ? colors.error : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
