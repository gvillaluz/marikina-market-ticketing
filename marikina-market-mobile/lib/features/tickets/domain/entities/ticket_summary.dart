import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';

class TicketSummary {
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

  const TicketSummary({
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
}
