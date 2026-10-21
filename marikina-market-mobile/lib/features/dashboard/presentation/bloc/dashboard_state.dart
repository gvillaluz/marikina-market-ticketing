import 'package:marikina_market_mobile/features/dashboard/domain/entities/dashboard_summary.dart';

abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardSummaryLoaded extends DashboardState {
  final DashboardSummary dashboardSummary;
  final bool isRefreshing;
  final String? errorMessage;

  bool get isEmpty =>
      dashboardSummary.totalRecorded == 0 &&
      dashboardSummary.ticketsRecorded == 0 &&
      dashboardSummary.warningsRecorded == 0;

  DashboardSummaryLoaded({
    required this.dashboardSummary,
    this.isRefreshing = false,
    this.errorMessage,
  });
}

class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
}
