import 'package:marikina_market_mobile/features/tickets/domain/entities/business_snapshot.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_summary.dart';

class InspectionVerification {
  final BusinessSnapshot? businessSnapshot;
  final FineSummary calculation;
  final String reviewedCalculation;
  final String? reviewedBusinessSnapshot;
  const InspectionVerification({
    this.businessSnapshot,
    this.reviewedBusinessSnapshot,
    required this.calculation,
    required this.reviewedCalculation,
  });
}
