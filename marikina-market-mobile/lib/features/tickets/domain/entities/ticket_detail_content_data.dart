import 'package:marikina_market_mobile/features/tickets/domain/entities/duplicate_ordinance.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_detail.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_settlement_data.dart';

class TicketDetailContentData {
  final TicketDetail ticket;
  final List<DuplicateOrdinance>? droppedOrdinances;
  final TicketSettlementData? settlement;

  const TicketDetailContentData({
    required this.ticket,
    required this.droppedOrdinances,
    required this.settlement,
  });
}
