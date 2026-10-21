import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import '../enums/records_filter.dart';
import 'record_violation.dart';

class VendorTicketDetail {
  final int ticketId;
  final String? controlNumber;
  final RecordsFilter type;
  final String businessName,
      vendorType,
      businessId,
      firstName,
      lastName,
      marketSection,
      description;
  final String? stallNumber, address, severity, penaltyType;
  final List<String> categories, evidenceUrls;
  final List<RecordViolation> violations;
  final DateTime issuedAt;
  final DateTime? dueDate;
  final TicketStatus? status;
  final double? totalFine;
  final int? communityServiceHours;
  const VendorTicketDetail({
    required this.ticketId,
    required this.controlNumber,
    required this.type,
    required this.businessName,
    required this.vendorType,
    required this.businessId,
    required this.firstName,
    required this.lastName,
    required this.marketSection,
    required this.description,
    required this.stallNumber,
    required this.address,
    required this.severity,
    required this.penaltyType,
    required this.categories,
    required this.evidenceUrls,
    required this.violations,
    required this.issuedAt,
    required this.dueDate,
    required this.status,
    required this.totalFine,
    required this.communityServiceHours,
  });
}
