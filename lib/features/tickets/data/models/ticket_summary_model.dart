import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_summary.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';

class TicketSummaryModel {
  final int ticketId;
  final int enforcerId;
  final int vendorId;
  final String controlNumber;
  final TicketStatus ticketStatus;
  final String businessName;
  final String stallNumber;
  final String marketSection;
  final DateTime issuedAt;
  final DateTime updatedAt;
  final DateTime overDueDate;

  const TicketSummaryModel({
    required this.ticketId,
    required this.enforcerId,
    required this.vendorId,
    required this.controlNumber,
    required this.ticketStatus,
    required this.businessName,
    required this.stallNumber,
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
      controlNumber: json['control_number'] as String,
      ticketStatus: TicketStatus.fromValue(json['status'] as String),
      businessName: json['business_name'] as String,
      stallNumber: json['stall_number'],
      marketSection: json['market_section_name'],
      issuedAt: DateTime.parse(json['issued_at'] as String),
      updatedAt: DateTime.parse(json['updated_at']),
      overDueDate: DateTime.parse(json['overdue_date'] as String),
    );
  }

  TicketSummary toEntity() {
    return TicketSummary(
      ticketId: ticketId,
      enforcerId: enforcerId,
      vendorId: vendorId,
      controlNumber: controlNumber,
      ticketStatus: ticketStatus,
      businessName: businessName,
      stallNumber: stallNumber,
      marketSection: marketSection,
      issuedAt: issuedAt,
      updatedAt: updatedAt,
      overDueDate: overDueDate,
    );
  }
}
