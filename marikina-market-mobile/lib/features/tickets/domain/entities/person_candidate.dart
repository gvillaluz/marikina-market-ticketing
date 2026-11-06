import 'package:marikina_market_mobile/features/tickets/domain/entities/person_ticket_totals.dart';

class PersonCandidate {
  final int id;
  final String fullName, address;
  final String? phoneNumber;
  final List<String> matchedFields;
  final PersonTicketTotals ticketTotals;
  const PersonCandidate({
    required this.id,
    required this.fullName,
    required this.address,
    this.phoneNumber,
    this.matchedFields = const [],
    this.ticketTotals = const PersonTicketTotals(),
  });
}
