import 'package:marikina_market_mobile/features/tickets/domain/entities/business_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/vendor_summary.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_field.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_section_title.dart';

class ViolatorInfoSection extends StatelessWidget {
  final VendorSummary vendor;
  final BusinessSnapshot? businessSnapshot;
  final bool isTicket;
  final String? paperViolatorName, personFullName;
  final int? personId;

  const ViolatorInfoSection({
    required this.vendor,
    this.businessSnapshot,
    this.paperViolatorName,
    this.personFullName,
    this.personId,
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
        if (isTicket)
          Text(
            businessSnapshot == null
                ? 'Current registry details. Verify to review the business details for this citation.'
                : 'Business details reviewed for this citation.',
          ),
        if (businessSnapshot != null) ...[
          TicketPaperField(
            label: 'BUSINESS ID:',
            value: businessSnapshot!.businessAccountNumber ?? 'Unavailable',
          ),
          TicketPaperField(
            label: 'TRADE NAME:',
            value: businessSnapshot!.businessName ?? 'Unavailable',
          ),
          TicketPaperField(
            label: 'REGISTERED OWNER:',
            value: businessSnapshot!.registeredOwnerName ?? 'Unavailable',
          ),
          TicketPaperField(
            label: 'BUSINESS TYPE:',
            value: businessSnapshot!.businessType ?? 'Unavailable',
          ),
          TicketPaperField(
            label: 'STALL/UNIT NO:',
            value: businessSnapshot!.stallNumber ?? 'Unavailable',
          ),
          TicketPaperField(
            label: 'MARKET SECTION:',
            value: businessSnapshot!.marketSectionName ?? 'Unavailable',
          ),
          TicketPaperField(
            label: 'ADDRESS:',
            value: businessSnapshot!.businessAddress ?? 'Unavailable',
          ),
        ] else ...[
          TicketPaperField(
            label: "STALL/UNIT NO:",
            value: vendor.stallNumber ?? 'N/A',
          ),
          const SizedBox(height: AppTheme.inspectionSmallGap),
          TicketPaperField(label: "TRADE NAME:", value: vendor.tradeName),
          const SizedBox(height: AppTheme.inspectionSmallGap),
          TicketPaperField(
            label: "REGISTERED OWNER:",
            value: '${vendor.lastName}, ${vendor.firstName}',
          ),
        ],
        ...[
          if (isTicket)
            TicketPaperField(
              label: 'RECORDED VIOLATOR:',
              value: paperViolatorName ?? 'Unconfirmed',
            ),
          TicketPaperField(
            label: 'CONFIRMED PERSON:',
            value: personId == null
                ? 'Unconfirmed'
                : '${personFullName ?? 'Person'} · Person $personId',
          ),
          const SizedBox(height: AppTheme.inspectionSmallGap),
          if (isTicket && businessSnapshot == null)
            TicketPaperField(label: "ADDRESS:", value: vendor.address),
        ],
      ],
    );
  }
}
