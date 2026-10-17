import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_detail.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/detail_row.dart';

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
      children: [
        const Wrap(
          spacing: AppTheme.ticketTinyGap,
          children: [
            Icon(Icons.person, color: AppColors.primary),
            Text(
              'VIOLATOR DETAILS',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: AppTheme.sectionHeadingFontSize,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        DetailRow(label: "BUSINESS ID:", value: ticket.businessId),
        const SizedBox(height: 10),
        DetailRow(label: "STALL/UNIT NO:", value: ticket.stallNumber ?? 'N/A'),
        const SizedBox(height: 10),
        DetailRow(label: "TRADE NAME:", value: ticket.tradeName),
        const SizedBox(height: 10),
        DetailRow(
          label: "NAME:",
          value: '${ticket.lastName}, ${ticket.firstName}',
        ),
        if (isTicket) ...[
          const SizedBox(height: 10),
          DetailRow(
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
