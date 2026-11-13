import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class TicketPaperHeader extends StatelessWidget {
  final bool isTicket;
  // The ticket's control number: the number printed on the paper ticket.
  final String? paperReference;
  const TicketPaperHeader({
    required this.isTicket,
    this.paperReference,
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
                    'CONTROL NUMBER:',
                    textAlign: TextAlign.right,
                    style: AppTheme.ticketPaperLabelStyle,
                  ),
                  Text(
                    paperReference == null
                        ? 'Unavailable (legacy record)'
                        : '#$paperReference',
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
