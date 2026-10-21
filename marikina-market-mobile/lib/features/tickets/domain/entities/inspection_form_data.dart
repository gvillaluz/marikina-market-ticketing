import 'package:image_picker/image_picker.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ordinance.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/vendor_summary.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';

class InspectionFormData {
  final int enforcerId;
  final VendorSummary vendorSummary;
  final FineSummary? fineSummary;
  final List<Ordinance> ordinances;
  final List<XFile>? evidences;
  final String description;
  final ViolationType ticketType;
  final PenaltyType? penaltyType;
  final int? communityServiceHrs;

  InspectionFormData({
    required this.enforcerId,
    required this.vendorSummary,
    required this.fineSummary,
    required this.ordinances,
    required this.evidences,
    required this.description,
    required this.ticketType,
    required this.penaltyType,
    required this.communityServiceHrs,
  });
}
