import 'dart:io';

import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/page_result.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/community_service_progress.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/submit_community_service_log_params.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_detail.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/ticket_receipt_proof.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_summary.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';

abstract class TicketRepository {
  Future<Result<PageResult<TicketSummary>>> loadTickets(
    String search,
    int offset,
    TicketStatus status,
  );
  Future<Result<TicketDetail>> getTicketDetail(int ticketId);
  Future<Result<TicketReceiptProof>> getTicketReceiptProof(int ticketId);
  Future<Result<CommunityServiceProgress>> getCommunityServiceProgress(
    int ticketId,
  );
  Future<Result<TicketReceiptProof>> submitTicketReceiptProof(
    int ticketId,
    File proofFile,
  );
  Future<Result<CommunityServiceProgress>> submitCommunityServiceLog(
    SubmitCommunityServiceLogParams params,
  );
}
