import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/widgets/count_card.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/widgets/dashboard_metric_layout.dart';

class DashboardSummaryCards extends StatelessWidget {
  const DashboardSummaryCards({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<DashboardBloc, DashboardState, (int, int, int)?>(
        selector: (state) => state is DashboardSummaryLoaded
            ? (
                state.dashboardSummary.ticketsRecorded,
                state.dashboardSummary.warningsRecorded,
                state.dashboardSummary.totalRecorded,
              )
            : null,
        builder: (context, counts) => counts == null
            ? const SizedBox.shrink()
            : DashboardMetricLayout(
                children: [
                  CountCard(type: 'Ticket', count: counts.$1, compact: true),
                  CountCard(type: 'Warning', count: counts.$2, compact: true),
                  CountCard(type: 'Total', count: counts.$3),
                ],
              ),
      );
}
