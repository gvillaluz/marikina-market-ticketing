import 'package:marikina_market_mobile/features/tickets/data/models/person_ticket_totals_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/person_candidate.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/person_ticket_totals.dart';

class PersonCandidateModel {
  final int id;
  final String fullName, address;
  final String? phoneNumber;
  final List<String> matchedFields;
  final PersonTicketTotalsModel? ticketTotals;
  const PersonCandidateModel({
    required this.id,
    required this.fullName,
    required this.address,
    this.phoneNumber,
    this.matchedFields = const [],
    this.ticketTotals,
  });
  // A person just created comes back without ticket totals.
  factory PersonCandidateModel.fromJson(Map<String, Object?> json) =>
      PersonCandidateModel(
        id: json['id'] as int,
        fullName: json['full_name'] as String,
        address: json['address'] as String,
        phoneNumber: json['phone_number'] as String?,
        matchedFields: (json['matched_fields'] as List<Object?>? ?? [])
            .cast<String>(),
        ticketTotals: json['ticket_totals'] == null
            ? null
            : PersonTicketTotalsModel.fromJson(
                json['ticket_totals'] as Map<String, Object?>,
              ),
      );
  PersonCandidate toEntity() => PersonCandidate(
    id: id,
    fullName: fullName,
    address: address,
    phoneNumber: phoneNumber,
    matchedFields: matchedFields,
    ticketTotals: ticketTotals?.toEntity() ?? const PersonTicketTotals(),
  );
}
