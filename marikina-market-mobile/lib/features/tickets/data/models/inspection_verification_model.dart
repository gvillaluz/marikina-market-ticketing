import 'package:marikina_market_mobile/features/tickets/data/models/business_snapshot_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/inspection_verification.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/fine_summary_model.dart';

class InspectionVerificationModel {
  final BusinessSnapshotModel? businessSnapshot;
  final FineSummaryModel calculation;
  final String reviewedCalculation;
  final String? reviewedBusinessSnapshot;
  const InspectionVerificationModel({
    this.businessSnapshot,
    this.reviewedBusinessSnapshot,
    required this.calculation,
    required this.reviewedCalculation,
  });
  factory InspectionVerificationModel.fromJson(Map<String, Object?> json) =>
      InspectionVerificationModel(
        businessSnapshot: json['business_snapshot'] == null
            ? null
            : BusinessSnapshotModel.fromJson(
                json['business_snapshot'] as Map<String, Object?>,
              ),

        calculation: FineSummaryModel.fromJson(
          json['calculation'] as Map<String, Object?>,
        ),
        reviewedCalculation: json['reviewed_calculation'] as String,
        reviewedBusinessSnapshot: json['reviewed_business_snapshot'] as String?,
      );
  InspectionVerification toEntity() => InspectionVerification(
    businessSnapshot: businessSnapshot?.toEntity(),
    calculation: calculation.toEntity(),
    reviewedCalculation: reviewedCalculation,
    reviewedBusinessSnapshot: reviewedBusinessSnapshot,
  );
}
