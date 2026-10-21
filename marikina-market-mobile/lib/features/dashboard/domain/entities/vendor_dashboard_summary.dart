import 'vendor_compliance.dart';
import 'vendor_dashboard_task.dart';

class VendorDashboardSummary {
  final int totalWarnings;
  final int totalTickets;
  final VendorCompliance compliance;
  final List<VendorDashboardTask> tasks;

  const VendorDashboardSummary({
    required this.totalWarnings,
    required this.totalTickets,
    required this.compliance,
    required this.tasks,
  });
}
