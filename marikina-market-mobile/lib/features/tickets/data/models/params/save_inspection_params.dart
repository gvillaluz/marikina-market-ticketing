import 'package:image_picker/image_picker.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';

class SaveInspectionParams {
  final int vendorId;
  final int marketSectionId;
  final int enforcerId;
  final ViolationType ticketType;
  final String description;
  final PenaltyType penaltyType;
  final int? communityServiceHours;
  final List<int> ordinanceIds;
  final List<XFile>? evidences;

  SaveInspectionParams({
    required this.vendorId,
    required this.marketSectionId,
    required this.enforcerId,
    required this.ticketType,
    required this.description,
    required this.penaltyType,
    required this.communityServiceHours,
    required this.ordinanceIds,
    required this.evidences,
  });
}
