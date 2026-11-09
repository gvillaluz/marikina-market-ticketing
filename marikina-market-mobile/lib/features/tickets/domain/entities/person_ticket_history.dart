import 'package:marikina_market_mobile/features/tickets/domain/entities/business_snapshot.dart';

class PersonTicketHistory {
  final BusinessSnapshot? businessSnapshot;
  final String? paperReference, issuePlace;
  final int ticketId;
  final String? businessName;
  final String enforcerName;
  final String? paperViolatorName, status, penaltyType;
  final DateTime issuedAt;
  final double? assessedCashFine;
  final double outstandingCashFine;
  final List<String> ordinances;
  const PersonTicketHistory({
    this.businessSnapshot,
    this.paperReference,
    this.issuePlace,
    required this.ticketId,
    required this.businessName,
    required this.enforcerName,
    this.paperViolatorName,
    this.status,
    this.penaltyType,
    required this.issuedAt,
    this.assessedCashFine,
    required this.outstandingCashFine,
    required this.ordinances,
  });

  bool get isUnregistered => businessName == null;
}
