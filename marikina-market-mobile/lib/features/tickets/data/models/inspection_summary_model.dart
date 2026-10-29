import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/inspection_ticket_summary.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/business_type.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';

class InspectionSummaryModel {
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

  InspectionSummaryModel({
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
    required this.businessAccountNumber,
    required this.businessType,
    this.stallNumber,
    this.status,
    required this.severity,
    required this.ordinance,
    required this.issuedAt,
    required this.overDueDate,
    required this.updatedAt,
  });

  factory InspectionSummaryModel.fromJson(Map<String, dynamic> json) {
    return InspectionSummaryModel(
      ticketId: json['id'] as int,
      ticketType: ViolationType.fromValue(json['type'] as String),
      controlNumber: json['control_number'] != null
          ? json['control_number'] as String
          : null,
      vendorId: json['vendor_id'] as int,
      personId: json['person_id'] as int?,
      personFullName: json['person_full_name'] as String?,
      paperViolatorName: json['paper_violator_name'] as String?,
      paperReference: json['paper_reference'] as String?,
      issuePlace: json['issue_place'] as String?,
      registeredOwnerName: json['registered_owner_name'] as String?,
      vendorFirstName: json['first_name'] as String,
      vendorLastName: json['last_name'] as String,
      businessName: json['business_name'] as String,
      marketSectionId: json['market_section_id'] as int,
      marketSection: json['market_section_name'] as String,
      enforcerId: json['enforcer_id'] as int,
      businessType: BusinessType.fromValue(json['business_type'] as String),
      businessAccountNumber: json['business_account_number'] as String,
      stallNumber: json['stall_number'] != null
          ? json['stall_number'] as String
          : null,
      status: json['status'] == null
          ? null
          : TicketStatus.fromValue(json['status'] as String),
      severity: json['severity'] == null
          ? null
          : Severity.fromValue(json['severity'] as String),
      ordinance: List<String>.from(json['ordinance_names'] as List),
      issuedAt: DateTime.parse(json['issued_at'] as String),
      overDueDate: json['overdue_date'] != null
          ? DateTime.parse(json['overdue_date'] as String)
          : null,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  factory InspectionSummaryModel.fromEntity(InspectionTicketSummary entity) {
    return InspectionSummaryModel(
      ticketId: entity.ticketId,
      paperReference: entity.paperReference,
      issuePlace: entity.issuePlace,
      ticketType: entity.ticketType,
      controlNumber: entity.controlNumber,
      vendorId: entity.vendorId,
      vendorFirstName: entity.vendorFirstName,
      vendorLastName: entity.vendorLastName,
      businessName: entity.businessName,
      marketSectionId: entity.marketSectionId,
      marketSection: entity.marketSection,
      enforcerId: entity.enforcerId,
      businessType: entity.businessType,
      businessAccountNumber: entity.businessAccountNumber,
      stallNumber: entity.stallNumber,
      status: entity.status,
      severity: entity.severity,
      ordinance: entity.ordinance,
      issuedAt: entity.issuedAt,
      overDueDate: entity.overDueDate,
      updatedAt: entity.updatedAt,
    );
  }

  InspectionTicketSummary toEntity() {
    return InspectionTicketSummary(
      ticketId: ticketId,
      ticketType: ticketType,
      controlNumber: controlNumber,
      vendorId: vendorId,
      personId: personId,
      personFullName: personFullName,
      paperViolatorName: paperViolatorName,
      paperReference: paperReference,
      issuePlace: issuePlace,
      registeredOwnerName: registeredOwnerName,
      vendorFirstName: vendorFirstName,
      vendorLastName: vendorLastName,
      businessName: businessName,
      marketSectionId: marketSectionId,
      marketSection: marketSection,
      enforcerId: enforcerId,
      businessType: businessType,
      businessAccountNumber: businessAccountNumber,
      stallNumber: stallNumber,
      status: status,
      severity: severity,
      ordinance: ordinance,
      issuedAt: issuedAt,
      overDueDate: overDueDate,
      updatedAt: updatedAt,
    );
  }
}
