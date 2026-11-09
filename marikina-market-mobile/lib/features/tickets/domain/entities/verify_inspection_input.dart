import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_assessment.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';

class VerifyInspectionInput {
  final List<FineAssessment> fineAssessments;
  final String? paperReference, issuePlace;
  final int? vendorId, marketSectionId;
  final int personId, evidenceCount;
  final int paperTicketPhotoCount, supportingEvidenceCount;
  final String paperViolatorName, description;
  final List<int> ordinanceIds;
  final PenaltyType penaltyType;
  final int? communityServiceHours;
  const VerifyInspectionInput({
    this.fineAssessments = const [],
    this.paperReference,
    this.issuePlace,
    this.vendorId,
    this.marketSectionId,
    required this.personId,
    required this.paperViolatorName,
    required this.description,
    required this.ordinanceIds,
    required this.penaltyType,
    this.communityServiceHours,
    required this.evidenceCount,
    this.paperTicketPhotoCount = 0,
    this.supportingEvidenceCount = 0,
  });
}
