import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_detail.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_field.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_section_title.dart';

class ViolatorDetailSection extends StatelessWidget {
  final TicketDetail ticket;
  final bool isTicket;

  const ViolatorDetailSection({
    required this.ticket,
    required this.isTicket,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TicketPaperSectionTitle(
          icon: Icons.person_outline,
          title: 'VIOLATOR DETAILS',
        ),
        const SizedBox(height: AppTheme.ticketSmallGap),
        TicketPaperField(
          label: "BUSINESS ID:",
          value: ticket.businessAccountNumber,
        ),
        const SizedBox(height: AppTheme.ticketSmallGap),
        TicketPaperField(
          label: "STALL/UNIT NO:",
          value: ticket.stallNumber ?? 'N/A',
        ),
        const SizedBox(height: AppTheme.ticketSmallGap),
        TicketPaperField(label: "TRADE NAME:", value: ticket.tradeName),
        const SizedBox(height: AppTheme.ticketSmallGap),
        TicketPaperField(
          label: "REGISTERED OWNER:",
          value: '${ticket.lastName}, ${ticket.firstName}',
        ),
        if (isTicket) ...[
          TicketPaperField(
            label: 'RECORDED VIOLATOR:',
            value: ticket.paperViolatorName ?? 'Unconfirmed (legacy record)',
          ),
          TicketPaperField(
            label: 'CONFIRMED PERSON:',
            value: ticket.personId == null
                ? 'Unconfirmed (legacy record)'
                : '${ticket.personFullName ?? 'Person'} · Person ${ticket.personId}',
          ),
          const SizedBox(height: AppTheme.ticketSmallGap),
          TicketPaperField(
            label: "ADDRESS:",
            value: ticket.address?.trim().isNotEmpty == true
                ? ticket.address!.trim()
                : 'Address is unavailable.',
          ),
        ],
      ],
    );
  }
}
