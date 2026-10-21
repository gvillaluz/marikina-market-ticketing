import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import '../../domain/entities/vendor_dashboard_summary.dart';
import 'vendor_compliance_card.dart';
import 'vendor_dashboard_task_card.dart';
import 'vendor_dashboard_totals.dart';
import 'vendor_dashboard_notice.dart';

class VendorDashboardContent extends StatelessWidget {
  final VendorDashboardSummary summary;
  final Future<void> Function() onRefresh;
  const VendorDashboardContent({
    required this.summary,
    required this.onRefresh,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 10),
      VendorDashboardTotals(
        warnings: summary.totalWarnings,
        tickets: summary.totalTickets,
      ),
      const SizedBox(height: AppTheme.dashboardGap),
      Text(
        'Your Compliance Score',
        style: AppTheme.sectionHeadingStyle.copyWith(
          color: AppTheme.profileHeroColor,
        ),
      ),
      const SizedBox(height: AppTheme.dashboardSmallGap),
      VendorComplianceCard(compliance: summary.compliance),
      const SizedBox(height: AppTheme.dashboardGap),
      Text(
        'Compliance Tasks',
        style: AppTheme.sectionHeadingStyle.copyWith(
          color: AppTheme.profileHeroColor,
        ),
      ),
      const SizedBox(height: AppTheme.dashboardSmallGap),
      if (summary.tasks.isEmpty)
        const VendorDashboardNotice(
          title: 'No active tickets',
          message: 'You have no pending compliance tasks right now.',
          icon: Icons.task_alt,
        ),
      for (final task in summary.tasks)
        VendorDashboardTaskCard(
          task: task,
          onOpen: () async {
            await context.pushNamed(
              Routes.vendorRecordDetailName,
              pathParameters: {'ticketId': '${task.ticketId}'},
            );
            if (context.mounted) await onRefresh();
          },
        ),
    ],
  );
}
