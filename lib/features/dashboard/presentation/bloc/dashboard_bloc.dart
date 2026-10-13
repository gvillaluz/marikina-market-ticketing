import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:marikina_market_mobile/features/dashboard/domain/use_cases/load_dashboard_summary_use_case.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/bloc/dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final LoadDashboardSummaryUseCase loadDashboardSummaryUseCase;

  DashboardBloc({required this.loadDashboardSummaryUseCase})
    : super(DashboardInitial()) {
    on<LoadDashboardSummary>(_onLoadDashboardSummary);
  }

  Future<void> refresh() async {
    if (isClosed) return;
    final finished = stream.firstWhere(
      (state) =>
          state is DashboardError ||
          state is DashboardSummaryLoaded && !state.isRefreshing,
    );
    add(LoadDashboardSummary());
    try {
      await finished;
    } on StateError {
      // A refresh also finishes when this screen's bloc closes.
    }
  }

  Future<void> _onLoadDashboardSummary(
    LoadDashboardSummary event,
    Emitter<DashboardState> emit,
  ) async {
    final previous = state;
    if (previous is DashboardLoading ||
        previous is DashboardSummaryLoaded && previous.isRefreshing) {
      return;
    }
    emit(
      previous is DashboardSummaryLoaded
          ? DashboardSummaryLoaded(
              dashboardSummary: previous.dashboardSummary,
              isRefreshing: true,
            )
          : DashboardLoading(),
    );

    final result = await loadDashboardSummaryUseCase();
    if (emit.isDone) return;

    switch (result) {
      case Success<DashboardSummary>(:final data):
        emit(DashboardSummaryLoaded(dashboardSummary: data));
      case ResultFailure<DashboardSummary>(:var failure):
        emit(
          previous is DashboardSummaryLoaded
              ? DashboardSummaryLoaded(
                  dashboardSummary: previous.dashboardSummary,
                  errorMessage: failure.message,
                )
              : DashboardError(failure.message),
        );
    }
  }
}
