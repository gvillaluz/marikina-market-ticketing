import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_detail.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/community_service_progress.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/ticket_receipt_proof.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_summary.dart';

abstract class TicketState {}

class TicketInitial extends TicketState {}

class TicketLoading extends TicketState {}

class TicketSilentLoading extends TicketState {}

class TicketsLoaded extends TicketState {
  final List<TicketSummary> ticketSummary;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isRefreshing;
  final String? errorMessage;
  final bool isLoadMoreError;

  TicketsLoaded(
    this.ticketSummary,
    this.hasMore, {
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.errorMessage,
    this.isLoadMoreError = false,
  });

  TicketsLoaded copyWith({
    List<TicketSummary>? ticketSummary,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isRefreshing,
    String? errorMessage,
    bool? isLoadMoreError,
    bool clearErrorMessage = false,
  }) {
    return TicketsLoaded(
      ticketSummary ?? this.ticketSummary,
      hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      isLoadMoreError: isLoadMoreError ?? this.isLoadMoreError,
    );
  }
}

class TicketError extends TicketState {
  final String message;
  TicketError(this.message);
}

class TicketDetailLoading extends TicketState {}

class TicketDetailLoaded extends TicketState {
  final TicketDetail ticket;
  final TicketReceiptProof? receiptProof;
  final CommunityServiceProgress? communityServiceProgress;
  final bool isSettlementLoading;
  final bool isSettlementLoaded;
  final bool isSubmittingSettlement;
  final bool isReceiptSubmitted;
  final String? settlementMessage;

  TicketDetailLoaded(
    this.ticket, {
    this.receiptProof,
    this.communityServiceProgress,
    this.isSettlementLoading = false,
    this.isSettlementLoaded = false,
    this.isSubmittingSettlement = false,
    this.isReceiptSubmitted = false,
    this.settlementMessage,
  });

  TicketDetailLoaded copyWith({
    TicketReceiptProof? receiptProof,
    CommunityServiceProgress? communityServiceProgress,
    bool? isSettlementLoading,
    bool? isSettlementLoaded,
    bool? isSubmittingSettlement,
    bool? isReceiptSubmitted,
    String? settlementMessage,
    bool clearSettlementMessage = false,
  }) {
    return TicketDetailLoaded(
      ticket,
      receiptProof: receiptProof ?? this.receiptProof,
      communityServiceProgress:
          communityServiceProgress ?? this.communityServiceProgress,
      isSettlementLoading: isSettlementLoading ?? this.isSettlementLoading,
      isSettlementLoaded: isSettlementLoaded ?? this.isSettlementLoaded,
      isSubmittingSettlement:
          isSubmittingSettlement ?? this.isSubmittingSettlement,
      isReceiptSubmitted: isReceiptSubmitted ?? this.isReceiptSubmitted,
      settlementMessage: clearSettlementMessage
          ? null
          : settlementMessage ?? this.settlementMessage,
    );
  }
}
