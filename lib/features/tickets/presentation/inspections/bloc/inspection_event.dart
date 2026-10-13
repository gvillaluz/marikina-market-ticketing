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
  final ViolationType type;
  LoadInspectionTickets({
    this.search = '',
    this.offset = 0,
    this.type = ViolationType.warning,
  });
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
  FineSummaryRequested(this.ordinanceIds, this.vendorId);
}

class WarningOrdinanceCheckRequested extends InspectionEvent {
  final List<int> ordinanceIds;
  final int vendorId;

  WarningOrdinanceCheckRequested(this.ordinanceIds, this.vendorId);
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

  NewInspectionSubmitted({
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
  });
}
