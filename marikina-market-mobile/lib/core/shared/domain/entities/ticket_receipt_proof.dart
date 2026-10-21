import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';

class TicketReceiptProof {
  final int ticketId;
  final PenaltyType penaltyType;
  final List<String> proofUrls;

  const TicketReceiptProof({
    required this.ticketId,
    required this.penaltyType,
    required this.proofUrls,
  });
}
