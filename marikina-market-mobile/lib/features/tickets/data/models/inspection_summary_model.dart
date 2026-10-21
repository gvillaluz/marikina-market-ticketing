import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/inspection_ticket_summary.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/vendor_type.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';

class InspectionSummaryModel {
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
  final VendorType vendorType;
  final String businessId;
  final String? stallNumber;
  final TicketStatus? status;
  final Severity? severity;
  final List<String> ordinance;
  final DateTime issuedAt;
  final DateTime? overDueDate;
  final DateTime updatedAt;

  InspectionSummaryModel({
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
    required this.businessId,
    required this.vendorType,
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
      vendorFirstName: json['first_name'] as String,
      vendorLastName: json['last_name'] as String,
      businessName: json['business_name'] as String,
      marketSectionId: json['market_section_id'] as int,
      marketSection: json['market_section_name'] as String,
      enforcerId: json['enforcer_id'] as int,
      vendorType: VendorType.fromValue(json['vendor_type'] as String),
      businessId: json['business_id'] as String,
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
      ticketType: entity.ticketType,
      controlNumber: entity.controlNumber,
      vendorId: entity.vendorId,
      vendorFirstName: entity.vendorFirstName,
      vendorLastName: entity.vendorLastName,
      businessName: entity.businessName,
      marketSectionId: entity.marketSectionId,
      marketSection: entity.marketSection,
      enforcerId: entity.enforcerId,
      vendorType: entity.vendorType,
      businessId: entity.businessId,
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
      vendorFirstName: vendorFirstName,
      vendorLastName: vendorLastName,
      businessName: businessName,
      marketSectionId: marketSectionId,
      marketSection: marketSection,
      enforcerId: enforcerId,
      vendorType: vendorType,
      businessId: businessId,
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
