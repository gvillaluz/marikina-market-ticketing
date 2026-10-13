import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import '../enums/records_filter.dart';

class VendorRecord {
  final int ticketId;
  final String? controlNumber;
  final RecordsFilter type;
  final List<String> violations;
  final DateTime issuedAt;
  final DateTime? overdueDate;
  final TicketStatus? status;
  const VendorRecord({
    required this.ticketId,
    required this.controlNumber,
    required this.type,
    required this.violations,
    required this.issuedAt,
    required this.overdueDate,
    required this.status,
  });
}
