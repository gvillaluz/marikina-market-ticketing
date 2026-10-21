import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/vendor_summary.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_field.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_section_title.dart';

class ViolatorInfoSection extends StatelessWidget {
  final VendorSummary vendor;
  final bool isTicket;

  const ViolatorInfoSection({
    required this.vendor,
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
          label: "STALL/UNIT NO:",
          value: vendor.stallNumber ?? 'N/A',
        ),
        const SizedBox(height: AppTheme.inspectionSmallGap),
        TicketPaperField(label: "TRADE NAME:", value: vendor.tradeName),
        const SizedBox(height: AppTheme.inspectionSmallGap),
        TicketPaperField(
          label: "NAME:",
          value: '${vendor.lastName}, ${vendor.firstName}',
        ),
        if (isTicket) ...[
          const SizedBox(height: AppTheme.inspectionSmallGap),
          TicketPaperField(label: "ADDRESS:", value: vendor.address),
        ],
      ],
    );
  }
}
