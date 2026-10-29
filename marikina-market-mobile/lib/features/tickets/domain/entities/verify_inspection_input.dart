import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';

class VerifyInspectionInput {
  final int vendorId, personId, evidenceCount;
  final String paperViolatorName, description;
  final List<int> ordinanceIds;
  final PenaltyType penaltyType;
  final int? communityServiceHours;
  const VerifyInspectionInput({
    required this.vendorId,
    required this.personId,
    required this.paperViolatorName,
    required this.description,
    required this.ordinanceIds,
    required this.penaltyType,
    this.communityServiceHours,
    required this.evidenceCount,
  });
}
