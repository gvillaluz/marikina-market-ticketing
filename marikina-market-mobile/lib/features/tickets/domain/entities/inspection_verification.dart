import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_summary.dart';

class InspectionVerification {
  final FineSummary calculation;
  final String reviewedCalculation;
  const InspectionVerification({
    required this.calculation,
    required this.reviewedCalculation,
  });
}
