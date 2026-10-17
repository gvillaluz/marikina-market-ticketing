import '../../domain/entities/vendor_dashboard_summary.dart';
import '../../domain/entities/vendor_compliance.dart';
import '../../domain/entities/vendor_dashboard_task.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';

class VendorDashboardModel {
  final Map<String, Object?> json;
  const VendorDashboardModel(this.json);

  VendorDashboardSummary toEntity() {
    final compliance = json['compliance'] as Map<String, Object?>;
    final score = (compliance['compliance_score'] as num).toInt();
    final warnings = (json['total_warnings'] as num).toInt();
    final tickets = (json['total_tickets'] as num).toInt();
    final paymentHistory = (compliance['penalty_payment_history'] as num)
        .toDouble();
    final days = (compliance['days_since_last_ticket'] as num?)?.toInt();
    if (score < 0 ||
        score > 100 ||
        warnings < 0 ||
        tickets < 0 ||
        !paymentHistory.isFinite ||
        paymentHistory < 0 ||
        paymentHistory > 100 ||
        (days != null && days < 0)) {
      throw const FormatException('Invalid dashboard summary.');
    }
    return VendorDashboardSummary(
      totalWarnings: warnings,
      totalTickets: tickets,
      compliance: VendorCompliance(
        score: score,
        standing: compliance['standing'] as String,
        frequencyLevel: compliance['violation_frequency_level'] as String,
        daysSinceLastTicket: days,
        severityLevel: compliance['category_severity_level'] as String,
        paymentHistory: paymentHistory,
      ),
      tasks: (json['tasks'] as List<Object?>).map((item) {
        final task = item as Map<String, Object?>;
        final id = (task['ticket_id'] as num).toInt();
        final penalty = PenaltyType.fromValue(task['penalty_type'] as String);
        final required = (task['hours_required'] as num?)?.toInt();
        final completed = (task['hours_completed'] as num).toDouble();
        if (id <= 0 ||
            id > 2147483647 ||
            !completed.isFinite ||
            completed < 0 ||
            (penalty == PenaltyType.communityService &&
                (required == null || required <= 0))) {
          throw const FormatException('Invalid dashboard task.');
        }
        return VendorDashboardTask(
          ticketId: id,
          controlNumber: task['control_number'] as String?,
          penaltyType: penalty,
          hoursRequired: required,
          hoursCompleted: completed,
        );
      }).toList(),
    );
  }
}
