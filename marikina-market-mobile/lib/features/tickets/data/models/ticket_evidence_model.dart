import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_evidence.dart';

class TicketEvidenceModel {
  final int id;
  final String? role;
  final int? sortOrder;
  final String url;
  const TicketEvidenceModel({
    required this.id,
    required this.role,
    required this.sortOrder,
    required this.url,
  });
  factory TicketEvidenceModel.fromJson(Map<String, Object?> json) =>
      TicketEvidenceModel(
        id: (json['id'] as num).toInt(),
        role: json['role'] as String?,
        sortOrder: (json['sort_order'] as num?)?.toInt(),
        url: json['url'] as String,
      );
  TicketEvidence toEntity() =>
      TicketEvidence(id: id, role: role, sortOrder: sortOrder, url: url);
}
