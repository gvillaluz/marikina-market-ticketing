export './inspection_verification_requested.dart';
export './person_history_requested.dart';
export './person_creation_requested.dart';
export './person_matches_requested.dart';

import 'package:image_picker/image_picker.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/ordinance_category.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';

abstract class InspectionEvent {}

class LoadOrdinances extends InspectionEvent {}

class LoadOrdinanceSelection extends InspectionEvent {}

class LoadInspectionTickets extends InspectionEvent {
  final String search;
  final int offset;
  final ViolationType? type;
  LoadInspectionTickets({this.search = '', this.offset = 0, this.type});
}

class SearchByCodeRequested extends InspectionEvent {
  final String codeValue;
  SearchByCodeRequested(this.codeValue);
}

class SearchByStallNumberRequested extends InspectionEvent {
  final String stallNumber;
  SearchByStallNumberRequested(this.stallNumber);
}

class FineSummaryRequested extends InspectionEvent {
  final List<int> ordinanceIds;
  final int? vendorId;
  final int? personId;
  FineSummaryRequested(this.ordinanceIds, this.vendorId, {this.personId});
}

class WarningOrdinanceCheckRequested extends InspectionEvent {
  final List<int> ordinanceIds;
  final int vendorId;

  final int? personId;
  WarningOrdinanceCheckRequested(
    this.ordinanceIds,
    this.vendorId, {
    this.personId,
  });
}

class NewTicketSubmitted extends InspectionEvent {
  final int vendorId;
  final int enforcerId;
  final ViolationType ticketType;
  final List<int> ordinanceIds;
  final String placeOfApprehension;
  final String description;
  final List<XFile> evidences;

  NewTicketSubmitted({
    required this.vendorId,
    required this.enforcerId,
    required this.ticketType,
    required this.ordinanceIds,
    required this.placeOfApprehension,
    required this.description,
    required this.evidences,
  });
}

class NewWarningSubmitted extends InspectionEvent {
  final int vendorId;
  final int enforcerId;
  final ViolationType ticketType;
  final int ordinanceId;
  final String placeOfApprehension;
  final String description;

  NewWarningSubmitted({
    required this.vendorId,
    required this.enforcerId,
    required this.ticketType,
    required this.ordinanceId,
    required this.placeOfApprehension,
    required this.description,
  });
}

class NewInspectionSubmitted extends InspectionEvent {
  final String? paperReference, issuePlace;
  final String? reviewedBusinessSnapshot;
  final int? personId;
  final String? paperViolatorName, reviewedCalculation;
  final int vendorId;
  final int enforcerId;
  final int marketSectionId;
  final ViolationType ticketType;
  final List<int> ordinanceIds;
  final PenaltyType penaltyType;
  final int? communityServiceHours;
  final String description;
  final List<OrdinanceCategory> primaryCategory;
  final List<XFile>? evidences;
  final XFile? paperTicketPhoto;

  NewInspectionSubmitted({
    this.paperReference,
    this.issuePlace,
    this.personId,
    this.paperViolatorName,
    this.reviewedCalculation,
    this.reviewedBusinessSnapshot,
    required this.vendorId,
    required this.enforcerId,
    required this.marketSectionId,
    required this.ticketType,
    required this.ordinanceIds,
    required this.penaltyType,
    required this.communityServiceHours,
    required this.description,
    required this.primaryCategory,
    required this.evidences,
    this.paperTicketPhoto,
  });
}
