import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/page_result.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_detail.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/submit_ticket_receipt_proof_params.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_summary.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/load_community_service_progress_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/load_ticket_detail_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/load_ticket_list_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/load_ticket_receipt_proof_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/submit_community_service_log_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/submit_ticket_receipt_proof_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/bloc/ticket_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/bloc/ticket_state.dart';

class TicketBloc extends Bloc<TicketEvent, TicketState> {
  final LoadTicketListUseCase loadTicketListUseCase;
  final LoadTicketDetailUseCase loadTicketDetailUseCase;
  final LoadTicketReceiptProofUseCase loadTicketReceiptProofUseCase;
  final LoadCommunityServiceProgressUseCase loadCommunityServiceProgressUseCase;
  final SubmitTicketReceiptProofUseCase submitTicketReceiptProofUseCase;
  final SubmitCommunityServiceLogUseCase submitCommunityServiceLogUseCase;

  List<TicketSummary> _ticketList = [];
  List<TicketSummary> get getTicketList => _ticketList;
  String _listSearch = '';
  TicketStatus _listStatus = TicketStatus.pending;
  bool _hasMoreTickets = false;
  bool _isLoadingMoreTickets = false;
  bool _isRefreshingTickets = false;
  bool _hasLoadedTickets = false;
  int _listRequestId = 0;

  TicketBloc({
    required this.loadTicketListUseCase,
    required this.loadTicketDetailUseCase,
    required this.loadTicketReceiptProofUseCase,
    required this.loadCommunityServiceProgressUseCase,
    required this.submitTicketReceiptProofUseCase,
    required this.submitCommunityServiceLogUseCase,
  }) : super(TicketInitial()) {
    on<LoadTicketSummary>(_onLoadTicketSummary);
    on<LoadTicketDetail>(_onLoadTicketDetail);
    on<LoadTicketSettlement>(_onLoadTicketSettlement);
    on<SubmitTicketReceiptProof>(_onSubmitTicketReceiptProof);
    on<SubmitCommunityServiceLog>(_onSubmitCommunityServiceLog);
  }

  Future<void> refreshTickets({
    required String search,
    required TicketStatus status,
  }) async {
    if (isClosed) return;
    final finished = stream.firstWhere(
      (state) =>
          state is TicketError ||
          state is TicketsLoaded && !state.isRefreshing && !state.isLoadingMore,
    );
    add(LoadTicketSummary(search: search, status: status));
    try {
      await finished;
    } on StateError {
      /* Screen closed. */
    }
  }

  Future<void> _onLoadTicketSummary(
    LoadTicketSummary event,
    Emitter<TicketState> emit,
  ) async {
    final isLoadMore = event.offset > 0;
    if (isLoadMore) {
      final current = state;
      if (_isLoadingMoreTickets ||
          _isRefreshingTickets ||
          current is! TicketsLoaded ||
          current.isRefreshing ||
          !current.hasMore ||
          !_hasMoreTickets ||
          event.offset != _ticketList.length ||
          event.search != _listSearch ||
          event.status != _listStatus) {
        return;
      }
      _isLoadingMoreTickets = true;
      emit(current.copyWith(isLoadingMore: true, clearErrorMessage: true));
    } else {
      final queryChanged =
          event.search != _listSearch || event.status != _listStatus;
      if (!queryChanged && _isRefreshingTickets) return;
      _isRefreshingTickets = true;
      _listSearch = event.search;
      _listStatus = event.status;
      _listRequestId++;
      _isLoadingMoreTickets = false;
      if (queryChanged) {
        _ticketList = [];
        _hasMoreTickets = false;
        _hasLoadedTickets = false;
      }

      if (!_hasLoadedTickets) {
        emit(TicketLoading());
      } else {
        emit(TicketsLoaded(_ticketList, _hasMoreTickets, isRefreshing: true));
      }
    }

    final requestId = _listRequestId;
    final result = await loadTicketListUseCase(
      event.search,
      event.offset,
      event.status,
    );
    if (emit.isDone || requestId != _listRequestId) return;
    _isRefreshingTickets = false;

    switch (result) {
      case Success<PageResult<TicketSummary>>():
        _ticketList = event.offset == 0
            ? result.data.items
            : [..._ticketList, ...result.data.items];
        _hasMoreTickets = result.data.hasMore && result.data.items.isNotEmpty;
        _hasLoadedTickets = true;
        _isLoadingMoreTickets = false;
        emit(TicketsLoaded(_ticketList, _hasMoreTickets));

      case ResultFailure(failure: final failure):
        _isLoadingMoreTickets = false;
        if (!_hasLoadedTickets) {
          emit(TicketError(failure.message));
        } else {
          emit(
            TicketsLoaded(
              _ticketList,
              _hasMoreTickets,
              errorMessage: failure.message,
              isLoadMoreError: isLoadMore,
            ),
          );
        }
    }
  }

  Future<void> _onLoadTicketDetail(
    LoadTicketDetail event,
    Emitter<TicketState> emit,
  ) async {
    emit(TicketDetailLoading());

    final result = await loadTicketDetailUseCase(event.ticketId);
    if (emit.isDone) return;

    switch (result) {
      case ResultFailure<TicketDetail>(:final failure):
        emit(TicketError(failure.message));

      case Success<TicketDetail>(:final data):
        final shouldLoadSettlement = data.violationType == ViolationType.ticket;
        emit(
          TicketDetailLoaded(data, isSettlementLoading: shouldLoadSettlement),
        );
        if (shouldLoadSettlement) {
          add(
            LoadTicketSettlement(
              ticketId: data.ticketId,
              penaltyType: data.penaltyType ?? PenaltyType.cashFine,
            ),
          );
        }
    }
  }

  Future<void> _onLoadTicketSettlement(
    LoadTicketSettlement event,
    Emitter<TicketState> emit,
  ) async {
    final current = state;
    if (current is! TicketDetailLoaded ||
        current.ticket.ticketId != event.ticketId) {
      return;
    }
    emit(
      current.copyWith(isSettlementLoading: true, clearSettlementMessage: true),
    );

    if (event.penaltyType == PenaltyType.communityService) {
      final result = await loadCommunityServiceProgressUseCase(event.ticketId);
      final latest = state;
      if (latest is! TicketDetailLoaded ||
          latest.ticket.ticketId != event.ticketId) {
        return;
      }
      switch (result) {
        case ResultFailure(:final failure):
          emit(
            latest.copyWith(
              isSettlementLoading: false,
              isSettlementLoaded: false,
              settlementMessage: failure.message,
            ),
          );
        case Success(:final data):
          emit(
            latest.copyWith(
              communityServiceProgress: data,
              isSettlementLoading: false,
              isSettlementLoaded: true,
            ),
          );
      }
      return;
    }

    final result = await loadTicketReceiptProofUseCase(event.ticketId);
    final latest = state;
    if (latest is! TicketDetailLoaded ||
        latest.ticket.ticketId != event.ticketId) {
      return;
    }
    switch (result) {
      case ResultFailure(:final failure):
        emit(
          latest.copyWith(
            isSettlementLoading: false,
            isSettlementLoaded: false,
            settlementMessage: failure.message,
          ),
        );
      case Success(:final data):
        emit(
          latest.copyWith(
            receiptProof: data,
            isReceiptSubmitted: data.proofUrls.isNotEmpty,
            isSettlementLoading: false,
            isSettlementLoaded: true,
          ),
        );
    }
  }

  Future<void> _onSubmitTicketReceiptProof(
    SubmitTicketReceiptProof event,
    Emitter<TicketState> emit,
  ) async {
    final current = state;
    if (current is! TicketDetailLoaded ||
        current.ticket.ticketId != event.ticketId ||
        current.ticket.ticketStatus == TicketStatus.paid ||
        current.isReceiptSubmitted ||
        !current.isSettlementLoaded ||
        current.isSubmittingSettlement) {
      return;
    }

    emit(
      current.copyWith(
        isSubmittingSettlement: true,
        clearSettlementMessage: true,
      ),
    );
    final result = await submitTicketReceiptProofUseCase(
      SubmitTicketReceiptProofParams(
        ticketId: event.ticketId,
        proofFile: event.proofFile,
      ),
    );

    final latest = state;
    if (latest is! TicketDetailLoaded ||
        latest.ticket.ticketId != event.ticketId) {
      return;
    }
    switch (result) {
      case ResultFailure(:final failure):
        emit(
          latest.copyWith(
            isSubmittingSettlement: false,
            settlementMessage: failure.message,
          ),
        );
      case Success(:final data):
        emit(
          latest.copyWith(
            receiptProof: data,
            isSettlementLoaded: true,
            isReceiptSubmitted: true,
            isSubmittingSettlement: false,
            settlementMessage: 'Settlement receipt saved.',
          ),
        );
    }
  }

  Future<void> _onSubmitCommunityServiceLog(
    SubmitCommunityServiceLog event,
    Emitter<TicketState> emit,
  ) async {
    final current = state;
    if (current is! TicketDetailLoaded ||
        current.ticket.ticketId != event.params.ticketId ||
        current.ticket.ticketStatus == TicketStatus.paid ||
        !current.isSettlementLoaded ||
        current.isSubmittingSettlement) {
      return;
    }

    final progress = current.communityServiceProgress;
    if (progress != null && progress.hoursCompleted >= progress.hoursRequired) {
      emit(
        current.copyWith(
          settlementMessage:
              'Community service is complete; no additional entries can be added.',
        ),
      );
      return;
    }

    emit(
      current.copyWith(
        isSubmittingSettlement: true,
        clearSettlementMessage: true,
      ),
    );
    final result = await submitCommunityServiceLogUseCase(event.params);

    final latest = state;
    if (latest is! TicketDetailLoaded ||
        latest.ticket.ticketId != event.params.ticketId) {
      return;
    }
    switch (result) {
      case ResultFailure(:final failure):
        emit(
          latest.copyWith(
            isSubmittingSettlement: false,
            settlementMessage: failure.message,
          ),
        );
      case Success(:final data):
        emit(
          latest.copyWith(
            communityServiceProgress: data,
            isSettlementLoaded: true,
            isSubmittingSettlement: false,
            settlementMessage: 'Community service hours saved.',
          ),
        );
    }
  }
}
