import 'dart:io';

import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/submit_community_service_log_params.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';

abstract class TicketEvent {}

class LoadTicketSummary extends TicketEvent {
  final String search;
  final int offset;
  final TicketStatus status;

  LoadTicketSummary({
    this.search = '',
    this.offset = 0,
    this.status = TicketStatus.pending,
  });
}

class LoadTicketDetail extends TicketEvent {
  final int ticketId;
  LoadTicketDetail(this.ticketId);
}

class LoadTicketSettlement extends TicketEvent {
  final int ticketId;
  final PenaltyType penaltyType;

  LoadTicketSettlement({required this.ticketId, required this.penaltyType});
}

class SubmitTicketReceiptProof extends TicketEvent {
  final int ticketId;
  final File proofFile;

  SubmitTicketReceiptProof({required this.ticketId, required this.proofFile});
}

class SubmitCommunityServiceLog extends TicketEvent {
  final SubmitCommunityServiceLogParams params;

  SubmitCommunityServiceLog(this.params);
}
