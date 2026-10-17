import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import '../../domain/entities/vendor_compliance.dart';

class VendorComplianceCard extends StatelessWidget {
  final VendorCompliance compliance;
  const VendorComplianceCard({required this.compliance, super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: AppTheme.dashboardCardPadding,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: AppTheme.controlRadius,
      border: Border.all(color: AppTheme.vendorDashboardCardBorder),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final graph = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: 'Compliance score',
              value: '${compliance.score} out of 100',
              child: SizedBox(
                width: AppTheme.vendorDashboardRingSize,
                height: AppTheme.vendorDashboardRingSize,
                child: Stack(
                  alignment: Alignment.center,
                  fit: StackFit.expand,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: compliance.score / 100),
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : AppTheme.vendorDashboardScoreDuration,
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) =>
                          CircularProgressIndicator(
                            value: value,
                            strokeWidth: AppTheme.vendorDashboardRingStroke,
                            color: AppTheme.profileHeroColor,
                            backgroundColor:
                                AppTheme.vendorDashboardTicketBackground,
                          ),
                    ),
                    Center(
                      child: ExcludeSemantics(
                        child: Text(
                          '${compliance.score}/100',
                          style: AppTheme.sectionHeadingStyle.copyWith(
                            color: AppTheme.profileHeroColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.dashboardSmallGap),
            _badge(compliance.standing, compliance.standing == 'Good Standing'),
          ],
        );
        final breakdown = Column(
          children: [
            _row(
              'Violation Frequency',
              compliance.frequencyLevel,
              compliance.frequencyLevel == 'Low',
            ),
            _row(
              'Recency',
              compliance.daysSinceLastTicket == null
                  ? 'No tickets'
                  : '${compliance.daysSinceLastTicket} days',
              true,
            ),
            _row(
              'Category Severity',
              compliance.severityLevel,
              compliance.severityLevel == 'Low',
            ),
            _row(
              'Penalty Payment History',
              '${compliance.paymentHistory.toStringAsFixed(0)}%',
              compliance.paymentHistory >= 80,
            ),
          ],
        );
        if (constraints.maxWidth < 310 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3) {
          return Column(
            children: [
              graph,
              const SizedBox(height: AppTheme.dashboardGap),
              breakdown,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            graph,
            const SizedBox(width: AppTheme.dashboardGap),
            Expanded(child: breakdown),
          ],
        );
      },
    ),
  );

  Widget _row(String label, String value, bool good) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppTheme.dashboardTinyGap),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTheme.vendorDashboardLabelStyle.copyWith(
              color: AppTheme.vendorDashboardMutedColor,
            ),
          ),
        ),
        const SizedBox(width: AppTheme.dashboardTinyGap),
        Flexible(child: _badge(value, good)),
      ],
    ),
  );

  Widget _badge(String text, bool good) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppTheme.dashboardTinyGap,
      vertical: 2,
    ),
    decoration: BoxDecoration(
      borderRadius: AppTheme.controlRadius,
      color: good
          ? AppTheme.vendorDashboardGoodBackground
          : AppTheme.vendorDashboardWarningBackground,
    ),
    child: Text(
      text,
      style: AppTheme.vendorDashboardLabelStyle.copyWith(
        fontWeight: FontWeight.w600,
        color: good
            ? AppTheme.vendorDashboardGoodColor
            : AppTheme.vendorDashboardWarningColor,
      ),
    ),
  );
}
