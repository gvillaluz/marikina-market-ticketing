import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class VendorTicketPaperSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const VendorTicketPaperSectionTitle({
    required this.icon,
    required this.title,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        icon,
        size: AppTheme.ticketIconSize,
        color: Theme.of(context).colorScheme.primary,
      ),
      const SizedBox(width: AppTheme.ticketTinyGap),
      Expanded(child: Text(title, style: AppTheme.ticketPaperSectionStyle)),
    ],
  );
}
