import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/unregistered_vendor.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/vendor_summary.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_field.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_field_group.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_section_title.dart';

class ViolatorInfoSection extends StatelessWidget {
  // Null when the vendor is not registered.
  final VendorSummary? vendor;
  final bool isTicket;
  final String? paperViolatorName, personFullName, personAddress;
  final int? personId;

  const ViolatorInfoSection({
    required this.vendor,
    this.paperViolatorName,
    this.personFullName,
    this.personAddress,
    this.personId,
    required this.isTicket,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final vendor = this.vendor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TicketPaperSectionTitle(
          icon: Icons.person_outline,
          title: 'VIOLATOR DETAILS',
        ),
        const SizedBox(height: AppTheme.ticketSmallGap),
        TicketPaperFieldGroup(
          spacing: AppTheme.inspectionSmallGap,
          fields: [
            if (vendor == null)
              const TicketPaperField(
                label: 'BUSINESS:',
                value: unregisteredVendorLabel,
              )
            else ...[
              TicketPaperField(
                label: "STALL/UNIT NO:",
                value: vendor.stallNumber ?? 'N/A',
              ),
              TicketPaperField(label: "TRADE NAME:", value: vendor.tradeName),
              TicketPaperField(
                label: "REGISTERED OWNER:",
                value: '${vendor.lastName}, ${vendor.firstName}',
              ),
            ],
            if (isTicket)
              TicketPaperField(
                label: 'RECORDED VIOLATOR:',
                value: paperViolatorName ?? 'Unconfirmed',
              ),
            TicketPaperField(
              label: 'CONFIRMED PERSON:',
              value: personId == null
                  ? 'Unconfirmed'
                  : personFullName ?? 'Person',
            ),
            if (isTicket && vendor != null)
              TicketPaperField(
                label: 'BUSINESS ADDRESS:',
                value: vendor.address,
              ),
            if (isTicket && personAddress != null)
              TicketPaperField(
                label: 'VIOLATOR ADDRESS:',
                value: personAddress!,
              ),
          ],
        ),
      ],
    );
  }
}
