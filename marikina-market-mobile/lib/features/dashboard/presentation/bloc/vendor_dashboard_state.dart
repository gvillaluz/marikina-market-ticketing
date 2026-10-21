import '../../domain/entities/vendor_dashboard_summary.dart';

class VendorDashboardState {
  final VendorDashboardSummary? summary;
  final bool isLoading;
  final String? error;
  const VendorDashboardState({
    this.summary,
    this.isLoading = false,
    this.error,
  });
}
