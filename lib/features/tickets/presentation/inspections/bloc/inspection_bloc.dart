import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/params/save_inspection_params.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/inspection_ticket_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ordinance.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/page_result.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/save_inspection_result.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/get_fine_summary_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/load_inspection_list_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/load_ordinances_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/save_inspection_ticket_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/search_vendor_by_code_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/search_vendor_by_stall_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/check_warning_ordinances_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/warning_ordinance.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';

class InspectionBloc extends Bloc<InspectionEvent, InspectionState> {
  final LoadInspectionListUseCase loadInspectionListUseCase;
  final LoadOrdinancesUseCase loadOrdinancesUseCase;
  final SearchVendorByCodeUseCase searchVendorByCodeUseCase;
  final SearchVendorByStallUseCase searchVendorByStallUseCase;
  final GetFineSummaryUseCase getFineSummaryUseCase;
  final CheckWarningOrdinancesUseCase checkWarningOrdinancesUseCase;
  final SaveInspectionTicketUseCase saveInspectionTicketUseCase;

  List<InspectionTicketSummary> _inspectionSummary = [];
  List<InspectionTicketSummary> get inspectionSummaries => _inspectionSummary;
  String _listSearch = '';
  ViolationType _listType = ViolationType.warning;
  bool _hasMoreInspections = false;
  bool _isLoadingMoreInspections = false;
  bool _isRefreshingInspections = false;
  int _listRequestId = 0;
  int _vendorSearchRequestId = 0;

  List<Ordinance> _ordinances = [];
  List<Ordinance> get ordinances => _ordinances;
  bool _hasLoadedTickets = false;

  InspectionBloc({
    required this.loadInspectionListUseCase,
    required this.loadOrdinancesUseCase,
    required this.searchVendorByCodeUseCase,
    required this.searchVendorByStallUseCase,
    required this.getFineSummaryUseCase,
    required this.checkWarningOrdinancesUseCase,
    required this.saveInspectionTicketUseCase,
  }) : super(InspectionInitial()) {
    on<LoadOrdinances>(_onLoadOrdinances);
    on<LoadInspectionTickets>(_onLoadInspectionTickets);
    on<SearchByCodeRequested>(_onSearchByCodeRequested);
    on<SearchByStallNumberRequested>(_onSearchByStallNumberRequested);
    on<LoadOrdinanceSelection>(_onLoadOrdinanceSelection);
    on<FineSummaryRequested>(_onFineSummaryRequested);
    on<WarningOrdinanceCheckRequested>(_onWarningOrdinanceCheckRequested);
    on<NewInspectionSubmitted>(_onNewInspectionSubmitted);
  }

  Future<void> _onLoadOrdinances(LoadOrdinances event, Emitter emit) async {
    final result = await loadOrdinancesUseCase();

    if (result is Success<List<Ordinance>>) {
      _ordinances = result.data;
    }
  }

  Future<void> refreshInspections({
    required String search,
    required ViolationType type,
  }) async {
    if (isClosed) return;
    final finished = stream.firstWhere(
      (state) =>
          state is InspectionError ||
          state is InspectionTicketsLoaded &&
              !state.isRefreshing &&
              !state.isLoadingMore,
    );
    add(LoadInspectionTickets(search: search, type: type));
    try {
      await finished;
    } on StateError {
      // Closing the screen also ends pull-to-refresh.
    }
  }

  Future<void> _onLoadInspectionTickets(
    LoadInspectionTickets event,
    Emitter<InspectionState> emit,
  ) async {
    final isLoadMore = event.offset > 0;
    if (isLoadMore) {
      final current = state;
      if (_isLoadingMoreInspections ||
          _isRefreshingInspections ||
          current is! InspectionTicketsLoaded ||
          !current.hasMore ||
          !_hasMoreInspections ||
          event.offset != _inspectionSummary.length ||
          event.search != _listSearch ||
          event.type != _listType) {
        return;
      }
      _isLoadingMoreInspections = true;
      emit(current.copyWith(isLoadingMore: true, clearErrorMessage: true));
    } else {
      final queryChanged =
          event.search != _listSearch || event.type != _listType;
      if (!queryChanged && _isRefreshingInspections) return;
      _isRefreshingInspections = true;
      _listSearch = event.search;
      _listType = event.type;
      _listRequestId++;
      _isLoadingMoreInspections = false;
      if (queryChanged) {
        _inspectionSummary = [];
        _hasMoreInspections = false;
        _hasLoadedTickets = false;
      }

      if (!_hasLoadedTickets) {
        emit(InspectionLoading());
      } else {
        emit(
          InspectionTicketsLoaded(
            _inspectionSummary,
            _hasMoreInspections,
            isRefreshing: true,
          ),
        );
      }
    }

    final requestId = _listRequestId;
    final result = await loadInspectionListUseCase(
      event.search,
      event.offset,
      event.type,
    );
    if (requestId != _listRequestId || emit.isDone) return;
    _isRefreshingInspections = false;

    switch (result) {
      case Success<PageResult<InspectionTicketSummary>>():
        _inspectionSummary = event.offset == 0
            ? result.data.items
            : [..._inspectionSummary, ...result.data.items];
        _hasLoadedTickets = true;
        _hasMoreInspections =
            result.data.hasMore && result.data.items.isNotEmpty;
        _isLoadingMoreInspections = false;
        emit(InspectionTicketsLoaded(_inspectionSummary, _hasMoreInspections));

      case ResultFailure<PageResult<InspectionTicketSummary>>(
        failure: final failure,
      ):
        _isLoadingMoreInspections = false;
        if (!_hasLoadedTickets) {
          emit(InspectionError(failure.message));
        } else {
          emit(
            InspectionTicketsLoaded(
              _inspectionSummary,
              _hasMoreInspections,
              errorMessage: failure.message,
              isLoadMoreError: isLoadMore,
            ),
          );
        }
    }
  }

  Future<void> _onSearchByCodeRequested(
    SearchByCodeRequested event,
    Emitter emit,
  ) async {
    emit(InspectionSearchLoading());

    final result = await searchVendorByCodeUseCase(event.codeValue);

    if (emit.isDone) return;
    switch (result) {
      case Success(:final data):
        emit(InspectionVendorSelected(data));

      case ResultFailure(failure: final failure):
        emit(InspectionSearchError(failure.message));
    }
  }

  Future<void> _onSearchByStallNumberRequested(
    SearchByStallNumberRequested event,
    Emitter<InspectionState> emit,
  ) async {
    final requestId = ++_vendorSearchRequestId;
    final query = event.stallNumber.trim();
    if (query.isEmpty) {
      emit(InspectionInitial());
      return;
    }
    emit(InspectionSearchLoading());

    final result = await searchVendorByStallUseCase(query);
    if (emit.isDone || requestId != _vendorSearchRequestId) return;

    switch (result) {
      case Success(:final data):
        emit(InspectionSearchList(data));

      case ResultFailure(failure: final failure):
        emit(InspectionSearchError(failure.message));
    }
  }

  Future<void> _onLoadOrdinanceSelection(
    LoadOrdinanceSelection event,
    Emitter emit,
  ) async {
    emit(OrdinanceSelectionLoading());

    if (_ordinances.isNotEmpty) {
      emit(OrdinanceSelectionLoaded(ordinances));
      return;
    }

    final result = await loadOrdinancesUseCase();

    if (emit.isDone) return;
    if (result is Success<List<Ordinance>>) {
      _ordinances = result.data;
      emit(OrdinanceSelectionLoaded(_ordinances));
    } else if (result is ResultFailure<List<Ordinance>>) {
      emit(OrdinanceSelectionError(result.failure.message));
    }
  }

  Future<void> _onFineSummaryRequested(
    FineSummaryRequested event,
    Emitter emit,
  ) async {
    if (event.vendorId == null) {
      emit(FineSummaryError('Vendor is required to calculate fines.'));
      return;
    }

    emit(FineSummaryLoading());

    final result = await getFineSummaryUseCase(
      event.ordinanceIds,
      event.vendorId,
    );

    if (emit.isDone) return;
    switch (result) {
      case Success<FineSummary>(data: final data):
        emit(FineSummaryLoaded(data));

      case ResultFailure(
        failure: NetworkFailure(:final message) ||
            ServerFailure(:final message),
      ):
        emit(FineSummaryNetworkError(message));

      case ResultFailure(failure: ValidationFailure(:final message)):
        emit(FineSummaryError(message));

      case ResultFailure():
        emit(FineSummaryError('Something went wrong. Please try again.'));
    }
  }

  Future<void> _onWarningOrdinanceCheckRequested(
    WarningOrdinanceCheckRequested event,
    Emitter<InspectionState> emit,
  ) async {
    emit(WarningOrdinanceCheckLoading());

    final result = await checkWarningOrdinancesUseCase(
      event.ordinanceIds,
      event.vendorId,
    );

    if (emit.isDone) return;
    switch (result) {
      case Success<List<WarningOrdinance>>(:final data):
        emit(WarningOrdinanceCheckLoaded(data));
      case ResultFailure(failure: final failure):
        emit(WarningOrdinanceCheckError(failure.message));
    }
  }

  Future<void> _onNewInspectionSubmitted(
    NewInspectionSubmitted event,
    Emitter<InspectionState> emit,
  ) async {
    if (state is SubmitNewTicketLoading) return;
    emit(SubmitNewTicketLoading());

    final result = await saveInspectionTicketUseCase(
      SaveInspectionParams(
        vendorId: event.vendorId,
        marketSectionId: event.marketSectionId,
        enforcerId: event.enforcerId,
        ticketType: event.ticketType,
        description: event.description,
        penaltyType: event.penaltyType,
        communityServiceHours: event.communityServiceHours,
        ordinanceIds: event.ordinanceIds,
        evidences: event.evidences,
      ),
    );

    if (emit.isDone) return;
    switch (result) {
      case Success<SaveInspectionResult>(:final data):
        emit(SubmitNewTicketSuccess(data));
        if (_hasLoadedTickets) {
          _inspectionSummary = [..._inspectionSummary, data.inspectionSummary];
        } else {
          add(LoadInspectionTickets());
        }

      case ResultFailure(
        failure: NetworkFailure(:final message) ||
            ServerFailure(:final message) ||
            CacheFailure(:final message) ||
            TokenValidationFailure(:final message),
      ):
        emit(InspectionSubmitConnectionError(message));

      case ResultFailure(
        failure: UnauthorizedFailure(:final message) ||
            ValidationFailure(:final message),
      ):
        emit(InspectionSubmitError(message));

      case ResultFailure(
        failure: ConflictFailure(:final message, :final droppedOrdinances),
      ):
        emit(DuplicationConflictInspection(message, droppedOrdinances));

      case ResultFailure(failure: DuplicateWarningFailure(:final message)):
        emit(DuplicateWarningConflict(message));
    }
  }
}
