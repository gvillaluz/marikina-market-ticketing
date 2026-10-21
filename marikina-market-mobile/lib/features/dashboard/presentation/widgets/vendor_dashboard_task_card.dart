import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import '../../domain/entities/vendor_dashboard_task.dart';

class VendorDashboardTaskCard extends StatelessWidget {
  final VendorDashboardTask task;
  final VoidCallback onOpen;
  const VendorDashboardTaskCard({
    required this.task,
    required this.onOpen,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final (title, action, icon) = switch (task.penaltyType) {
      PenaltyType.cashFine => (
        'Pay pending ticket',
        'Review',
        Icons.description_outlined,
      ),
      PenaltyType.bloodDonation => (
        'Upload settlement proof',
        'Upload',
        Icons.add_photo_alternate_outlined,
      ),
      PenaltyType.communityService => (
        'Complete Community Service',
        'View Details',
        Icons.volunteer_activism_outlined,
      ),
    };
    final service = task.penaltyType == PenaltyType.communityService;
    final description = switch (task.penaltyType) {
      PenaltyType.cashFine =>
        'Settle the outstanding penalty for ${task.controlNumber ?? 'this ticket'}.',
      PenaltyType.bloodDonation =>
        'Add a settlement proof photo for ${task.controlNumber ?? 'this ticket'}.',
      PenaltyType.communityService =>
        'Complete the required community service for ${task.controlNumber ?? 'this ticket'}.',
    };
    final compact =
        MediaQuery.sizeOf(context).width < 320 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final button = TextButton(
      onPressed: onOpen,
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.profileHeroColor,
        backgroundColor: AppTheme.vendorDashboardTicketBackground,
      ),
      child: Text(
        action,
        style: AppTheme.vendorDashboardLabelStyle.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.dashboardSmallGap),
      padding: AppTheme.dashboardCompactCardPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppTheme.controlRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: AppTheme.profileHeroColor,
                size: AppTheme.dashboardIconSize,
              ),
              const SizedBox(width: AppTheme.dashboardSmallGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.vendorDashboardDetailStyle.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      description,
                      style: AppTheme.vendorDashboardLabelStyle.copyWith(
                        color: AppTheme.vendorDashboardMutedColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: AppTheme.dashboardTinyGap),
                button,
              ],
            ],
          ),
          if (compact) Align(alignment: Alignment.centerRight, child: button),
          if (service) ...[
            const SizedBox(height: AppTheme.dashboardSmallGap),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: AppTheme.dashboardSmallGap,
              children: [
                Text(
                  'Hours completed',
                  style: AppTheme.vendorDashboardLabelStyle.copyWith(
                    color: AppTheme.vendorDashboardMutedColor,
                  ),
                ),
                Text(
                  '${task.hoursCompleted.toStringAsFixed(1)} / ${task.hoursRequired ?? 0} hours completed',
                  style: AppTheme.vendorDashboardLabelStyle.copyWith(
                    color: AppTheme.profileHeroColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.dashboardTinyGap),
            LinearProgressIndicator(
              value: task.progress,
              color: AppTheme.profileHeroColor,
              backgroundColor: AppTheme.vendorDashboardTicketBackground,
              borderRadius: AppTheme.controlRadius,
              semanticsLabel: 'Community service progress',
            ),
          ],
        ],
      ),
    );
  }
}
