import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ordinance.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_field.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_field_group.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_section_title.dart';

// What the enforcer writes on the paper ticket or warning, using the paper's
// own labels and order. Shown only once everything it lists is ready.
class CopyToPaperCard extends StatelessWidget {
  final bool isTicket;
  final String name, address, place, officerName;
  final List<Ordinance> ordinances;
  final PenaltyType penaltyType;
  final double? fineTotal;
  final int? communityHours;
  final DateTime now;

  const CopyToPaperCard({
    required this.isTicket,
    required this.name,
    required this.address,
    required this.place,
    required this.officerName,
    required this.ordinances,
    required this.penaltyType,
    required this.fineTotal,
    required this.communityHours,
    required this.now,
    super.key,
  });

  static final _amount = NumberFormat('#,##0.00', 'en_PH');

  bool get _isReady =>
      name.isNotEmpty &&
      place.trim().isNotEmpty &&
      ordinances.isNotEmpty &&
      (!isTicket ||
          (address.isNotEmpty &&
              switch (penaltyType) {
                PenaltyType.cashFine => fineTotal != null,
                PenaltyType.bloodDonation => true,
                PenaltyType.communityService =>
                  communityHours != null && communityHours! >= 3,
              }));

  String get _finePenalty => switch (penaltyType) {
    PenaltyType.cashFine when fineTotal == 1500 || fineTotal == 1000 =>
      'tick Php ${_amount.format(fineTotal)}',
    PenaltyType.cashFine =>
      'tick OTHERS, write Php ${_amount.format(fineTotal)}',
    PenaltyType.bloodDonation => 'tick Blood Donation',
    PenaltyType.communityService =>
      'tick Community Service, write $communityHours hrs',
  };

  String _sectionAndTitle(Ordinance ordinance) =>
      ordinance.section == null || ordinance.section!.isEmpty
      ? ordinance.title
      : 'Sec. ${ordinance.section} – ${ordinance.title}';

  String _ticketOrdinance(Ordinance ordinance) =>
      ordinance.section == null || ordinance.section!.isEmpty
      ? '${ordinance.ordinanceNo} series of ${ordinance.series} – ${ordinance.title}'
      : '${ordinance.ordinanceNo} series of ${ordinance.series}, ${_sectionAndTitle(ordinance)}';

  List<TicketPaperField> get _ticketFields => [
    TicketPaperField(label: 'NAME:', value: name),
    TicketPaperField(label: 'ADDRESS:', value: address),
    TicketPaperField(
      label: 'ORDINANCE:',
      value: [
        'tick OTHERS, write:',
        ...ordinances.map(_ticketOrdinance),
      ].join('\n'),
    ),
    TicketPaperField(label: 'FINE/PENALTIES:', value: _finePenalty),
    TicketPaperField(label: 'PLACE:', value: place.trim()),
    TicketPaperField(
      label: 'DATE / TIME:',
      value: DateFormat('h:mm a M/d/y').format(now),
    ),
    TicketPaperField(
      label: 'NAME & SIGNATURE OF APPREHENDING OFFICER:',
      value: officerName,
    ),
  ];

  List<TicketPaperField> get _warningFields => [
    TicketPaperField(label: 'Petsa:', value: DateFormat('M/d/y').format(now)),
    TicketPaperField(label: 'Pangalan:', value: name),
    TicketPaperField(label: 'Lugar:', value: place.trim()),
    for (final ordinance in ordinances)
      TicketPaperField(
        label: 'Ordinansa Blg.:',
        value:
            '${ordinance.ordinanceNo}, Serye: ${ordinance.series}\n'
            '${_sectionAndTitle(ordinance)}',
      ),
    TicketPaperField(label: 'Market Enforcer:', value: officerName),
  ];

  @override
  Widget build(BuildContext context) {
    if (!_isReady) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.inspectionGap),
      child: Container(
        width: double.infinity,
        padding: AppTheme.ticketCardPadding,
        decoration: AppTheme.ticketPaperDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppTheme.inspectionSmallGap,
          children: [
            TicketPaperSectionTitle(
              icon: Icons.edit_note,
              title: isTicket
                  ? 'Copy these onto the paper ticket'
                  : 'Copy these onto the paper warning',
            ),
            TicketPaperFieldGroup(
              spacing: AppTheme.inspectionSmallGap,
              fields: isTicket ? _ticketFields : _warningFields,
            ),
          ],
        ),
      ),
    );
  }
}
