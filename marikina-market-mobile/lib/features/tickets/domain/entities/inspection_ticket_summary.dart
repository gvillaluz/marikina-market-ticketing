import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/business_type.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';

class InspectionTicketSummary {
  final String? paperReference, issuePlace;
  final int? personId;
  final String? personFullName, paperViolatorName, registeredOwnerName;
  final int ticketId;
  final ViolationType ticketType;
  final String? controlNumber;
  final int vendorId;
  final String vendorFirstName;
  final String vendorLastName;
  final String businessName;
  final int marketSectionId;
  final String marketSection;
  final int enforcerId;
  final BusinessType businessType;
  final String businessAccountNumber;
  final String? stallNumber;
  final TicketStatus? status;
  final Severity? severity;
  final List<String> ordinance;
  final DateTime issuedAt;
  final DateTime? overDueDate;
  final DateTime updatedAt;

  InspectionTicketSummary({
    this.paperReference,
    this.issuePlace,
    this.personId,
    this.personFullName,
    this.paperViolatorName,
    this.registeredOwnerName,
    required this.ticketId,
    required this.ticketType,
    this.controlNumber,
    required this.vendorId,
    required this.vendorFirstName,
    required this.vendorLastName,
    required this.businessName,
    required this.marketSectionId,
    required this.marketSection,
    required this.enforcerId,
    required this.businessType,
    required this.businessAccountNumber,
    required this.stallNumber,
    this.status,
    required this.severity,
    required this.ordinance,
    required this.issuedAt,
    required this.overDueDate,
    required this.updatedAt,
  });
}
