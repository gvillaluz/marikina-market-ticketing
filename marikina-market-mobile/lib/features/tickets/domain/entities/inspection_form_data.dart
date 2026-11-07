import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_assessment.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ordinance.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/vendor_summary.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';

class InspectionFormData {
  final List<FineAssessment> fineAssessments;
  final String? paperReference, issuePlace;
  final int? personId;
  final String? paperViolatorName,
      personFullName,
      personAddress,
      reviewedCalculation;
  final int enforcerId;
  final VendorSummary vendorSummary;
  final FineSummary? fineSummary;
  final List<Ordinance> ordinances;
  final List<XFile>? evidences;
  final XFile? paperTicketPhoto;
  final String description;
  final ViolationType ticketType;
  final PenaltyType? penaltyType;
  final int? communityServiceHrs;

  InspectionFormData({
    this.fineAssessments = const [],
    this.paperReference,
    this.issuePlace,
    this.personId,
    this.paperViolatorName,
    this.personFullName,
    this.personAddress,
    this.reviewedCalculation,
    required this.enforcerId,
    required this.vendorSummary,
    required this.fineSummary,
    required this.ordinances,
    required this.evidences,
    this.paperTicketPhoto,
    required this.description,
    required this.ticketType,
    required this.penaltyType,
    required this.communityServiceHrs,
  });
}
