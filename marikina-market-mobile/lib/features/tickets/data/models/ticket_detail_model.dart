import 'package:marikina_market_mobile/features/tickets/data/models/ticket_evidence_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/business_snapshot_model.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/violation_summary_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_detail.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/ordinance_category.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/business_type.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';

class TicketDetailModel {
  final BusinessSnapshotModel? businessSnapshot;
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
  final List<ViolationSummaryModel> violations;
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
  final List<TicketEvidenceModel> evidenceItems;

  const TicketDetailModel({
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

  factory TicketDetailModel.fromJson(Map<String, dynamic> json) {
    return TicketDetailModel(
      businessSnapshot: json['business_snapshot'] == null
          ? null
          : BusinessSnapshotModel.fromJson(
              json['business_snapshot'] as Map<String, Object?>,
            ),

      ticketId: json['ticket_id'] as int,
      controlNumber: json['control_number'] as String?,
      enforcerId: json['enforcer_id'] as int,
      vendorId: json['vendor_id'] as int,
      personId: json['person_id'] as int?,
      personFullName: json['person_full_name'] as String?,
      paperViolatorName: json['paper_violator_name'] as String?,
      paperReference: json['paper_reference'] as String?,
      issuePlace: json['issue_place'] as String?,
      registeredOwnerName: json['registered_owner_name'] as String?,
      violationType: ViolationType.fromValue(json['type'] as String),
      businessType: BusinessType.fromValue(json['business_type'] as String),
      businessAccountNumber: json['business_account_number'] as String,
      stallNumber: json['stall_number'] != null
          ? json['stall_number'] as String
          : null,
      tradeName: json['business_name'] as String,
      lastName: json['last_name'] as String,
      firstName: json['first_name'] as String,
      address: json['address'] as String?,
      violations: (json['violations'] as List<dynamic>)
          .map(
            (item) =>
                ViolationSummaryModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      issuedAt: DateTime.parse(json['issued_at'] as String),
      marketSectionName: json['market_section_name'] as String,
      categories: (json['categories'] as List<dynamic>)
          .map((value) => OrdinanceCategory.fromValue(value as String))
          .toList(),
      description: json['description'] as String,
      severity: json['severity'] == null
          ? null
          : Severity.fromValue(json['severity'] as String),
      penaltyType: json['penalty_type'] == null
          ? null
          : PenaltyType.fromValue(json['penalty_type'] as String),
      dueDate: json['due_date'] == null
          ? null
          : DateTime.parse(json['due_date'] as String),
      totalFineAmount: json['total_fine_amount'] == null
          ? null
          : (json['total_fine_amount'] as num).toDouble(),
      communityServiceHours: (json['community_service_hours'] as num?)?.toInt(),
      ticketStatus: json['status'] != null
          ? TicketStatus.fromValue(json['status'] as String)
          : null,
      evidenceItems: (json['evidence_items'] as List<Object?>? ?? [])
          .map(
            (item) =>
                TicketEvidenceModel.fromJson(item as Map<String, Object?>),
          )
          .toList(),
      evidenceUrls: json['ticket_evidences'] == null
          ? null
          : List<String>.from(json['ticket_evidences'] as List),
    );
  }

  TicketDetail toEntity() {
    return TicketDetail(
      ticketId: ticketId,
      controlNumber: controlNumber,
      enforcerId: enforcerId,
      vendorId: vendorId,
      personId: personId,
      personFullName: personFullName,
      paperViolatorName: paperViolatorName,
      businessSnapshot: businessSnapshot?.toEntity(),
      paperReference: paperReference,
      issuePlace: issuePlace,
      registeredOwnerName: registeredOwnerName,
      violationType: violationType,
      businessType: businessType,
      businessAccountNumber: businessAccountNumber,
      stallNumber: stallNumber,
      tradeName: tradeName,
      lastName: lastName,
      firstName: firstName,
      address: address,
      violations: violations.map((m) => m.toEntity()).toList(),
      issuedAt: issuedAt,
      marketSectionName: marketSectionName,
      categories: categories,
      description: description,
      severity: severity,
      penaltyType: penaltyType,
      dueDate: dueDate,
      totalFineAmount: totalFineAmount,
      communityServiceHours: communityServiceHours,
      ticketStatus: ticketStatus,
      evidenceUrls: evidenceUrls,
      evidenceItems: evidenceItems.map((item) => item.toEntity()).toList(),
    );
  }
}
