import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_summary.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';

class TicketSummaryModel {
  final int? personId;
  final String? personFullName, paperViolatorName, registeredOwnerName;
  final int ticketId;
  final int enforcerId;
  final int vendorId;
  final String controlNumber;
  final TicketStatus ticketStatus;
  final String businessName;
  final String? stallNumber;
  final List<String> ordinance;
  final String marketSection;
  final DateTime issuedAt;
  final DateTime updatedAt;
  final DateTime? overDueDate;

  const TicketSummaryModel({
    this.personId,
    this.personFullName,
    this.paperViolatorName,
    this.registeredOwnerName,
    required this.ticketId,
    required this.enforcerId,
    required this.vendorId,
    required this.controlNumber,
    required this.ticketStatus,
    required this.businessName,
    required this.stallNumber,
    this.ordinance = const [],
    required this.marketSection,
    required this.issuedAt,
    required this.updatedAt,
    required this.overDueDate,
  });

  factory TicketSummaryModel.fromJson(Map<String, dynamic> json) {
    return TicketSummaryModel(
      ticketId: json['id'] as int,
      enforcerId: json['enforcer_id'] as int,
      vendorId: json['vendor_id'] as int,
      personId: json['person_id'] as int?,
      personFullName: json['person_full_name'] as String?,
      paperViolatorName: json['paper_violator_name'] as String?,
      registeredOwnerName: json['registered_owner_name'] as String?,
      controlNumber: json['control_number'] as String,
      ticketStatus: TicketStatus.fromValue(json['status'] as String),
      businessName: json['business_name'] as String,
      stallNumber: json['stall_number'] as String?,
      ordinance: List<String>.from(
        json['ordinance_names'] as List? ?? const <String>[],
      ),
      marketSection: json['market_section_name'] as String,
      issuedAt: DateTime.parse(json['issued_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      overDueDate: json['overdue_date'] == null
          ? null
          : DateTime.parse(json['overdue_date'] as String),
    );
  }

  TicketSummary toEntity() {
    return TicketSummary(
      ticketId: ticketId,
      enforcerId: enforcerId,
      vendorId: vendorId,
      personId: personId,
      personFullName: personFullName,
      paperViolatorName: paperViolatorName,
      registeredOwnerName: registeredOwnerName,
      controlNumber: controlNumber,
      ticketStatus: ticketStatus,
      businessName: businessName,
      stallNumber: stallNumber,
      ordinance: ordinance,
      marketSection: marketSection,
      issuedAt: issuedAt,
      updatedAt: updatedAt,
      overDueDate: overDueDate,
    );
  }
}
