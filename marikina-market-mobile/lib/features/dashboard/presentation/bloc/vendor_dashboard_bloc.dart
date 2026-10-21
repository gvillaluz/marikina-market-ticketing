import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import '../../domain/use_cases/load_vendor_dashboard_use_case.dart';
import 'load_vendor_dashboard.dart';
import 'vendor_dashboard_state.dart';

class VendorDashboardBloc
    extends Bloc<LoadVendorDashboard, VendorDashboardState> {
  final LoadVendorDashboardUseCase loadDashboard;
  VendorDashboardBloc(this.loadDashboard)
    : super(const VendorDashboardState()) {
    on<LoadVendorDashboard>(_load);
  }

  Future<void> refresh() async {
    if (isClosed) return;
    final finished = stream.firstWhere((state) => !state.isLoading);
    add(const LoadVendorDashboard());
    try {
      await finished;
    } on StateError {
      // Closing the page also ends its refresh.
    }
  }

  Future<void> _load(
    LoadVendorDashboard event,
    Emitter<VendorDashboardState> emit,
  ) async {
    if (state.isLoading) return;
    final previous = state.summary;
    emit(VendorDashboardState(summary: previous, isLoading: true));
    final result = await loadDashboard();
    if (emit.isDone) return;
    switch (result) {
      case Success(:final data):
        emit(VendorDashboardState(summary: data));
      case ResultFailure(:final failure):
        emit(VendorDashboardState(summary: previous, error: failure.message));
    }
  }
}
