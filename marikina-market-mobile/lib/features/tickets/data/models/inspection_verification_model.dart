import 'package:marikina_market_mobile/features/tickets/domain/entities/inspection_verification.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/fine_summary_model.dart';

class InspectionVerificationModel {
  final FineSummaryModel calculation;
  final String reviewedCalculation;
  const InspectionVerificationModel({
    required this.calculation,
    required this.reviewedCalculation,
  });
  factory InspectionVerificationModel.fromJson(Map<String, Object?> json) =>
      InspectionVerificationModel(
        calculation: FineSummaryModel.fromJson(
          json['calculation'] as Map<String, Object?>,
        ),
        reviewedCalculation: json['reviewed_calculation'] as String,
      );
  InspectionVerification toEntity() => InspectionVerification(
    calculation: calculation.toEntity(),
    reviewedCalculation: reviewedCalculation,
  );
}
