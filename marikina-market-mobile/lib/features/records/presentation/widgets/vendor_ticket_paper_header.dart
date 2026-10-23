import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class VendorTicketPaperHeader extends StatelessWidget {
  final bool isTicket;
  final String? controlNumber;
  const VendorTicketPaperHeader({
    required this.isTicket,
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
          if (controlNumber != null)
            Expanded(
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'CONTROL NO.',
                    textAlign: TextAlign.right,
                    style: AppTheme.ticketPaperLabelStyle,
                  ),
                  Text(
                    '#$controlNumber',
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
