import 'package:flutter/material.dart';
import 'ticket_paper_field.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class TicketPaperHeader extends StatelessWidget {
  final bool isTicket;
  final String? paperReference;
  final String? controlNumber;
  const TicketPaperHeader({
    required this.isTicket,
    this.paperReference,
    this.controlNumber,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'City of Marikina',
        textAlign: TextAlign.center,
        style: AppTheme.ticketPaperOfficeStyle,
      ),
      Text(
        'Marikina Public Market Office',
        textAlign: TextAlign.center,
        style: AppTheme.ticketPaperLabelStyle,
      ),
      const SizedBox(height: AppTheme.ticketSmallGap),
      if (isTicket) ...[
        TicketPaperField(
          label: 'PAPER REFERENCE:',
          value: paperReference ?? 'Unavailable (legacy record)',
        ),
        const SizedBox(height: AppTheme.ticketSmallGap),
      ],
      Row(
        spacing: AppTheme.ticketSmallGap,
        children: [
          Expanded(
            flex: 3,
            child: Row(
              spacing: AppTheme.ticketTinyGap,
              children: [
                Image.asset(
                  'assets/logo/org_logo.png',
                  height: AppTheme.ticketPaperLogoSize,
                  width: AppTheme.ticketPaperLogoSize,
                ),
                Expanded(
                  child: Text(
                    isTicket ? 'VIOLATION TICKET' : 'WRITTEN WARNING',
                    style: AppTheme.ticketPaperHeadingStyle,
                  ),
                ),
              ],
            ),
          ),
          if (isTicket)
            Expanded(
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'SYSTEM CONTROL:',
                    textAlign: TextAlign.right,
                    style: AppTheme.ticketPaperLabelStyle,
                  ),
                  Text(
                    controlNumber == null ? 'PENDING' : '#$controlNumber',
                    textAlign: TextAlign.right,
                    style: AppTheme.ticketPaperControlStyle,
                  ),
                ],
              ),
            ),
        ],
      ),
    ],
  );
}
