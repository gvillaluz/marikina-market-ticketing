import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import '../../domain/entities/vendor_ticket_detail.dart';
import '../../domain/enums/records_filter.dart';
import 'record_violation_model.dart';

class VendorTicketDetailModel {
  final Map<String, Object?> json;
  const VendorTicketDetailModel._(this.json);
  factory VendorTicketDetailModel.fromJson(Map<String, Object?> json) =>
      VendorTicketDetailModel._(json);
  VendorTicketDetail toEntity() {
    final id = json['ticket_id'] as int;
    if (id <= 0) throw const FormatException('Invalid ticket ID.');
    final urls = (json['ticket_evidences'] as List<Object?>? ?? [])
        .cast<String>()
        .where((url) {
          final uri = Uri.tryParse(url);
          return uri != null &&
              (uri.scheme == 'https' || uri.scheme == 'http') &&
              uri.host.isNotEmpty;
        })
        .toList();
    return VendorTicketDetail(
      ticketId: id,
      controlNumber: json['control_number'] as String?,
      type: RecordsFilter.fromType(json['type'] as String),
      businessName: json['business_name'] as String,
      businessType: json['business_type'] as String,
      businessAccountNumber: json['business_account_number'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      marketSection: json['market_section_name'] as String,
      description: json['description'] as String,
      stallNumber: json['stall_number'] as String?,
      address: json['address'] as String?,
      severity: json['severity'] as String?,
      penaltyType: json['penalty_type'] as String?,
      categories: List<String>.unmodifiable(
        (json['categories'] as List<Object?>).cast<String>(),
      ),
      evidenceUrls: List.unmodifiable(urls),
      violations: List.unmodifiable(
        (json['violations'] as List<Object?>).map(
          (item) => RecordViolationModel.fromJson(
            item as Map<String, Object?>,
          ).toEntity(),
        ),
      ),
      issuedAt: DateTime.parse(json['issued_at'] as String),
      dueDate: json['due_date'] == null
          ? null
          : DateTime.parse(json['due_date'] as String),
      status: json['status'] == null
          ? null
          : TicketStatus.fromValue(json['status'] as String),
      totalFine: (json['total_fine_amount'] as num?)?.toDouble(),
      communityServiceHours: (json['community_service_hours'] as num?)?.toInt(),
    );
  }
}
