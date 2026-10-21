import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import '../../domain/entities/vendor_record.dart';
import '../../domain/enums/records_filter.dart';

class VendorRecordModel {
  final Map<String, Object?> json;
  const VendorRecordModel._(this.json);
  factory VendorRecordModel.fromJson(Map<String, Object?> json) =>
      VendorRecordModel._(json);
  VendorRecord toEntity() {
    final id = json['ticket_id'] as int;
    if (id <= 0) throw const FormatException('Invalid ticket ID.');
    return VendorRecord(
      ticketId: id,
      controlNumber: json['control_number'] as String?,
      type: RecordsFilter.fromType(json['type'] as String),
      violations: List<String>.unmodifiable(
        (json['violations'] as List<Object?>).cast<String>(),
      ),
      issuedAt: DateTime.parse(json['issued_at'] as String),
      overdueDate: json['overdue_date'] == null
          ? null
          : DateTime.parse(json['overdue_date'] as String),
      status: json['ticket_status'] == null
          ? null
          : TicketStatus.fromValue(json['ticket_status'] as String),
    );
  }
}
