import 'package:marikina_market_mobile/features/tickets/domain/use_cases/match_people_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/create_person_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/get_person_history_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/person_candidate.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/person_ticket_history.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/params/save_inspection_params.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/inspection_ticket_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ordinance.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ordinance_shortcuts.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/page_result.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/save_inspection_result.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/get_fine_summary_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/load_inspection_list_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/load_ordinances_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/save_inspection_ticket_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/get_market_sections_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/get_ordinance_shortcuts_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/search_businesses_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/get_business_people_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/get_owner_person_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/add_owner_person_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/use_cases/check_warning_ordinances_use_case.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/warning_ordinance.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';

class InspectionBloc extends Bloc<InspectionEvent, InspectionState> {
  final MatchPeopleUseCase matchPeopleUseCase;
  final CreatePersonUseCase createPersonUseCase;
  final GetPersonHistoryUseCase getPersonHistoryUseCase;
  final LoadInspectionListUseCase loadInspectionListUseCase;
  final LoadOrdinancesUseCase loadOrdinancesUseCase;
  final GetMarketSectionsUseCase getMarketSectionsUseCase;
  final SearchBusinessesUseCase searchBusinessesUseCase;
  final GetOrdinanceShortcutsUseCase getOrdinanceShortcutsUseCase;
  final GetBusinessPeopleUseCase getBusinessPeopleUseCase;
  final GetOwnerPersonUseCase getOwnerPersonUseCase;
  final AddOwnerPersonUseCase addOwnerPersonUseCase;
  final GetFineSummaryUseCase getFineSummaryUseCase;
  final CheckWarningOrdinancesUseCase checkWarningOrdinancesUseCase;
  final SaveInspectionTicketUseCase saveInspectionTicketUseCase;

  void invalidatePersonSearch() {
    ++_personMatchRequest;
  }

  int _personMatchRequest = 0;
  bool _creatingPerson = false;
  // Businesses whose owner is being added, so a double tap sends one POST.
  final Set<int> _addingOwners = {};
  List<InspectionTicketSummary> _inspectionSummary = [];
  List<InspectionTicketSummary> get inspectionSummaries => _inspectionSummary;
  String _listSearch = '';
  ViolationType? _listType;
  bool _hasMoreInspections = false;
  bool _isLoadingMoreInspections = false;
  bool _isRefreshingInspections = false;
  int _listRequestId = 0;
  int _vendorSearchRequestId = 0;

  List<Ordinance> _ordinances = [];
  List<Ordinance> get ordinances => _ordinances;
  OrdinanceShortcuts? _ordinanceShortcuts;
  int _ordinanceShortcutsRequestId = 0;
  OrdinanceShortcuts? get ordinanceShortcuts => _ordinanceShortcuts;
  bool _hasLoadedTickets = false;

  InspectionBloc({
    required this.matchPeopleUseCase,
    required this.createPersonUseCase,
    required this.getPersonHistoryUseCase,
    required this.loadInspectionListUseCase,
    required this.loadOrdinancesUseCase,
    required this.getMarketSectionsUseCase,
    required this.searchBusinessesUseCase,
    required this.getOrdinanceShortcutsUseCase,
    required this.getBusinessPeopleUseCase,
    required this.getOwnerPersonUseCase,
    required this.addOwnerPersonUseCase,
    required this.getFineSummaryUseCase,
    required this.checkWarningOrdinancesUseCase,
    required this.saveInspectionTicketUseCase,
  }) : super(InspectionInitial()) {
    on<PersonMatchesRequested>((event, emit) async {
      final request = ++_personMatchRequest;
      final result = await matchPeopleUseCase(event.name, event.offset);
      if (emit.isDone || request != _personMatchRequest) return;
      switch (result) {
        case Success<PageResult<PersonCandidate>>(:final data):
          emit(PersonMatchesLoaded(data, event.name, event.offset));
        case ResultFailure(:final failure):
          emit(PersonMatchesError(failure.message));
      }
    });
    on<PersonCreationRequested>((event, emit) async {
      if (_creatingPerson) return;
      _creatingPerson = true;
      emit(PersonCreationLoading());
      try {
        final result = await createPersonUseCase(
          event.name,
          event.address,
          event.phone,
        );
        if (emit.isDone) return;
        switch (result) {
          case Success<PersonCandidate>(:final data):
            emit(PersonCreated(data));
          // No reply from the server, so there is no server message.
          case ResultFailure(failure: NetworkFailure()):
            emit(PersonCreationError(null));
          case ResultFailure(:final failure):
            emit(PersonCreationError(failure.message));
        }
      } finally {
        _creatingPerson = false;
      }
    });
    on<PersonHistoryRequested>((event, emit) async {
      emit(PersonHistoryLoading());
      final result = await getPersonHistoryUseCase(
        event.personId,
        event.offset,
      );
      if (emit.isDone) return;
      switch (result) {
        case Success<PageResult<PersonTicketHistory>>(:final data):
          emit(PersonHistoryLoaded(data, event.personId, event.offset));
        case ResultFailure(:final failure):
          emit(PersonHistoryError(failure.message));
      }
    });
    on<LoadOrdinances>(_onLoadOrdinances);
    on<LoadInspectionTickets>(_onLoadInspectionTickets);
    on<MarketSectionsRequested>(_onMarketSectionsRequested);
    on<BusinessSearchRequested>(_onBusinessSearchRequested);
    on<BusinessPeopleRequested>(_onBusinessPeopleRequested);
    on<OwnerPersonRequested>(_onOwnerPersonRequested);
    on<OwnerPersonAddRequested>(_onOwnerPersonAddRequested);
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
    required ViolationType? type,
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

  Future<void> _onMarketSectionsRequested(
    MarketSectionsRequested event,
    Emitter<InspectionState> emit,
  ) async {
    emit(MarketSectionsLoading());
    final result = await getMarketSectionsUseCase();
    if (emit.isDone) return;
    switch (result) {
      case Success(:final data):
        emit(MarketSectionsLoaded(data));
      case ResultFailure(:final failure):
        emit(MarketSectionsError(failure.message));
    }
  }

  Future<void> _onBusinessSearchRequested(
    BusinessSearchRequested event,
    Emitter<InspectionState> emit,
  ) async {
    final requestId = ++_vendorSearchRequestId;
    final query = event.search.trim();
    if (query.isEmpty) {
      emit(InspectionInitial());
      return;
    }
    emit(InspectionSearchLoading());

    final result = await searchBusinessesUseCase(query);
    if (emit.isDone || requestId != _vendorSearchRequestId) return;

    switch (result) {
      case Success(:final data):
        emit(InspectionSearchList(data.items, data.hasMore));

      case ResultFailure(failure: final failure):
        emit(InspectionSearchError(failure.message));
    }
  }

  Future<void> _onBusinessPeopleRequested(
    BusinessPeopleRequested event,
    Emitter<InspectionState> emit,
  ) async {
    emit(BusinessPeopleLoading());
    final result = await getBusinessPeopleUseCase(event.businessId);
    if (emit.isDone) return;
    switch (result) {
      case Success(:final data):
        emit(BusinessPeopleLoaded(data));
      case ResultFailure(:final failure):
        emit(BusinessPeopleError(failure.message));
    }
  }

  Future<void> _onOwnerPersonRequested(
    OwnerPersonRequested event,
    Emitter<InspectionState> emit,
  ) async {
    emit(OwnerPersonLoading(event.businessId));
    final result = await getOwnerPersonUseCase(event.businessId);
    if (emit.isDone) return;
    switch (result) {
      case Success(:final data):
        emit(OwnerPersonLoaded(event.businessId, data));
      case ResultFailure(:final failure):
        emit(OwnerPersonError(event.businessId, failure.message));
    }
  }

  Future<void> _onOwnerPersonAddRequested(
    OwnerPersonAddRequested event,
    Emitter<InspectionState> emit,
  ) async {
    if (!_addingOwners.add(event.businessId)) return;
    emit(OwnerPersonAdding(event.businessId));
    try {
      final result = await addOwnerPersonUseCase(event.businessId);
      if (emit.isDone) return;
      switch (result) {
        case Success(:final data):
          emit(OwnerPersonAdded(event.businessId, data));
        case ResultFailure(:final failure):
          emit(OwnerPersonAddError(event.businessId, failure.message));
      }
    } finally {
      _addingOwners.remove(event.businessId);
    }
  }

  Future<void> _onLoadOrdinanceSelection(
    LoadOrdinanceSelection event,
    Emitter emit,
  ) async {
    final request = ++_ordinanceShortcutsRequestId;
    _ordinanceShortcuts = null;
    emit(OrdinanceSelectionLoading());

    if (_ordinances.isEmpty) {
      final result = await loadOrdinancesUseCase();
      if (emit.isDone) return;
      if (result is ResultFailure<List<Ordinance>>) {
        emit(OrdinanceSelectionError(result.failure.message));
        return;
      }
      _ordinances = (result as Success<List<Ordinance>>).data;
    }
    emit(OrdinanceSelectionLoaded(_ordinances));

    // Shortcuts are extra: the list is already usable, and a failure just leaves them out.
    final shortcuts = await getOrdinanceShortcutsUseCase(event.personId);
    if (emit.isDone || request != _ordinanceShortcutsRequestId) return;
    if (shortcuts is Success<OrdinanceShortcuts> &&
        state is OrdinanceSelectionLoaded) {
      _ordinanceShortcuts = shortcuts.data;
      emit(OrdinanceSelectionLoaded(_ordinances));
    }
  }

  Future<void> _onFineSummaryRequested(
    FineSummaryRequested event,
    Emitter emit,
  ) async {
    emit(FineSummaryLoading());

    final result = await getFineSummaryUseCase(
      event.ordinanceIds,
      event.vendorId,
      personId: event.personId,
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
      personId: event.personId,
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
        fineAssessments: event.fineAssessments,
        personId: event.personId,
        paperViolatorName: event.paperViolatorName,
        paperReference: event.paperReference,
        issuePlace: event.issuePlace,
        vendorId: event.vendorId,
        marketSectionId: event.marketSectionId,
        enforcerId: event.enforcerId,
        ticketType: event.ticketType,
        description: event.description,
        penaltyType: event.penaltyType,
        communityServiceHours: event.communityServiceHours,
        ordinanceIds: event.ordinanceIds,
        evidences: event.evidences,
        paperTicketPhoto: event.paperTicketPhoto,
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
