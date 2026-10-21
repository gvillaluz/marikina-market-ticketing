import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class VendorDashboardTotals extends StatelessWidget {
  final int warnings;
  final int tickets;
  const VendorDashboardTotals({
    required this.warnings,
    required this.tickets,
    super.key,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final warningCard = _card(
        '$warnings',
        'Total warnings',
        AppTheme.vendorDashboardWarningBackground,
        AppTheme.vendorDashboardWarningColor,
      );
      final ticketCard = _card(
        '$tickets',
        'Total violation tickets',
        AppTheme.vendorDashboardTicketBackground,
        AppTheme.profileHeroColor,
      );
      if (constraints.maxWidth < 300 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.3) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            warningCard,
            const SizedBox(height: AppTheme.dashboardSmallGap),
            ticketCard,
          ],
        );
      }
      return Row(
        children: [
          Expanded(child: warningCard),
          const SizedBox(width: AppTheme.dashboardSmallGap),
          Expanded(child: ticketCard),
        ],
      );
    },
  );

  Widget _card(
    String value,
    String label,
    Color background,
    Color foreground,
  ) => Container(
    padding: AppTheme.dashboardCardPadding,
    decoration: BoxDecoration(
      color: background,
      borderRadius: AppTheme.dashboardCardRadius,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTheme.dashboardCountStyle.copyWith(color: foreground),
        ),
        const SizedBox(height: AppTheme.dashboardTinyGap),
        Text(label, style: AppTheme.vendorDashboardDetailStyle),
      ],
    ),
  );
}
