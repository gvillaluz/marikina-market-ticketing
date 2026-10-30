import 'package:marikina_market_mobile/features/tickets/data/models/business_snapshot_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/person_ticket_history.dart';

class PersonTicketHistoryModel {
  final Map<String, Object?> _json;
  const PersonTicketHistoryModel._(this._json);
  factory PersonTicketHistoryModel.fromJson(Map<String, Object?> json) =>
      PersonTicketHistoryModel._(json);
  PersonTicketHistory toEntity() => PersonTicketHistory(
    businessSnapshot: _json['business_snapshot'] == null
        ? null
        : BusinessSnapshotModel.fromJson(
            _json['business_snapshot'] as Map<String, Object?>,
          ).toEntity(),
    ticketId: _json['ticket_id'] as int,
    reference: _json['control_number'] as String? ?? 'Unnumbered',
    businessName: _json['business_name'] as String,
    enforcerName: _json['enforcer_name'] as String,
    paperViolatorName: _json['paper_violator_name'] as String?,
    paperReference: _json['paper_reference'] as String?,
    issuePlace: _json['issue_place'] as String?,
    status: _json['status'] as String?,
    penaltyType: _json['penalty_type'] as String?,
    issuedAt: DateTime.parse(_json['issued_at'] as String),
    assessedCashFine: (_json['assessed_cash_fine'] as num?)?.toDouble(),
    outstandingCashFine: (_json['outstanding_cash_fine'] as num).toDouble(),
    ordinances: (_json['ordinances'] as List<Object?>).cast<String>(),
  );
}
