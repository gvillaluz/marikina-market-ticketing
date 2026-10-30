import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_evidence.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/business_snapshot.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/violation_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/ordinance_category.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/business_type.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';

class TicketDetail {
  final BusinessSnapshot? businessSnapshot;
  final String? paperReference, issuePlace;
  final int? personId;
  final String? personFullName, paperViolatorName, registeredOwnerName;
  final int ticketId;
  final String? controlNumber;
  final int enforcerId;
  final int vendorId;
  final ViolationType violationType;
  final BusinessType businessType;
  final String businessAccountNumber;
  final String? stallNumber;
  final String tradeName;
  final String lastName;
  final String firstName;
  final String? address;
  final List<ViolationSummary> violations;
  final DateTime issuedAt;
  final String marketSectionName;
  final List<OrdinanceCategory> categories;
  final String description;
  final Severity? severity;
  final PenaltyType? penaltyType;
  final DateTime? dueDate;
  final double? totalFineAmount;
  final int? communityServiceHours;
  final TicketStatus? ticketStatus;
  final List<String>? evidenceUrls;
  final List<TicketEvidence> evidenceItems;

  const TicketDetail({
    this.businessSnapshot,
    this.paperReference,
    this.issuePlace,
    this.personId,
    this.personFullName,
    this.paperViolatorName,
    this.registeredOwnerName,
    required this.ticketId,
    this.controlNumber,
    required this.enforcerId,
    required this.vendorId,
    required this.violationType,
    required this.businessType,
    required this.businessAccountNumber,
    this.stallNumber,
    required this.tradeName,
    required this.lastName,
    required this.firstName,
    required this.address,
    required this.violations,
    required this.issuedAt,
    required this.marketSectionName,
    required this.categories,
    required this.description,
    this.severity,
    this.penaltyType,
    this.dueDate,
    this.totalFineAmount,
    this.communityServiceHours,
    this.ticketStatus,
    this.evidenceUrls,
    this.evidenceItems = const [],
  });
}
