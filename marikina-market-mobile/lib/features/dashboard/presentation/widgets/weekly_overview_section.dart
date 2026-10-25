import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/widgets/dashboard_summary_cards.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/widgets/dashboard_notice.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/widgets/dashboard_overview_skeleton.dart';

class WeeklyOverviewSection extends StatelessWidget {
  const WeeklyOverviewSection({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<DashboardBloc, DashboardState>(
    builder: (context, state) {
      final Widget content;
      if (state is DashboardSummaryLoaded) {
        content = Column(
          key: const ValueKey('summary'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppTheme.dashboardSmallGap,
          children: [
            if (state.errorMessage != null)
              DashboardNotice(
                title: 'Overview could not be refreshed',
                message: state.errorMessage!.trim().isEmpty
                    ? 'Please try again to update your overview.'
                    : state.errorMessage!,
                icon: Icons.cloud_off_outlined,
                onRetry: () =>
                    context.read<DashboardBloc>().add(LoadDashboardSummary()),
              ),
            if (state.isEmpty)
              const DashboardNotice(
                title: 'No activity this week',
                message: 'Your recorded tickets and warnings will appear here.',
                icon: Icons.calendar_today_outlined,
              ),
            const DashboardSummaryCards(),
          ],
        );
      } else if (state is DashboardError) {
        content = DashboardNotice(
          key: const ValueKey('error'),
          title: 'Unable to load your overview',
          message: state.message.trim().isEmpty
              ? 'Please try again to load your weekly activity.'
              : state.message,
          icon: Icons.cloud_off_outlined,
          onRetry: () =>
              context.read<DashboardBloc>().add(LoadDashboardSummary()),
        );
      } else {
        content = const DashboardOverviewSkeleton(key: ValueKey('loading'));
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'This week’s overview',
                  style: AppTheme.dashboardHeadingStyle.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.dashboardSmallGap),
              SizedBox.square(
                dimension: AppTheme.buttonIconSize,
                child: state is DashboardSummaryLoaded && state.isRefreshing
                    ? CircularProgressIndicator(
                        value: MediaQuery.disableAnimationsOf(context)
                            ? 0.75
                            : null,
                        strokeWidth: AppTheme.buttonProgressStrokeWidth,
                        semanticsLabel: 'Refreshing overview',
                      )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.dashboardSmallGap),
          AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : AppTheme.pageTransitionDuration,
            reverseDuration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : AppTheme.pageReverseTransitionDuration,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: content,
          ),
        ],
      );
    },
  );
}
