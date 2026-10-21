import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/community_service_progress.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/ticket_receipt_proof.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';

class TicketSettlementData {
  final int ticketId;
  final PenaltyType penaltyType;
  final TicketStatus ticketStatus;
  final int? requiredHours;
  final TicketReceiptProof? receiptProof;
  final bool isReceiptSubmitted;
  final CommunityServiceProgress? communityServiceProgress;
  final bool isLoading;
  final bool isLoaded;
  final bool isSubmitting;

  const TicketSettlementData({
    required this.ticketId,
    required this.penaltyType,
    required this.ticketStatus,
    required this.isReceiptSubmitted,
    required this.isLoading,
    required this.isLoaded,
    required this.isSubmitting,
    this.requiredHours,
    this.receiptProof,
    this.communityServiceProgress,
  });
}
