import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import '../../../domain/entities/records_page_data.dart';
import '../../../domain/enums/records_filter.dart';
import '../../../domain/use_cases/load_records_use_case.dart';
import 'load_records.dart';
import 'records_state.dart';

class RecordsBloc extends Bloc<LoadRecords, RecordsState> {
  final LoadRecordsUseCase loadRecords;
  int _requestId = 0;
  bool _refreshing = false;
  bool _hasLoaded = false;
  RecordsBloc(this.loadRecords) : super(const RecordsState()) {
    on<LoadRecords>(_load);
  }
  Future<void> refreshRecords(String search, RecordsFilter filter) async {
    if (isClosed) return;
    final completed = stream.firstWhere(
      (state) =>
          !state.isInitialLoading &&
          !state.isRefreshing &&
          !state.isLoadingMore,
    );
    add(LoadRecords(search: search, filter: filter));
    try {
      await completed;
    } on StateError {
      /* Screen closed during refresh. */
    }
  }

  Future<void> _load(LoadRecords event, Emitter<RecordsState> emit) async {
    final changed =
        event.search.trim() != state.search || event.filter != state.filter;
    final more = event.offset > 0;
    if (more) {
      if (changed ||
          !state.hasMore ||
          state.isLoadingMore ||
          _refreshing ||
          state.isInitialLoading ||
          event.offset != state.items.length) {
        return;
      }
      emit(state.copyWith(isLoadingMore: true, isLoadMoreError: false));
    } else {
      if (!changed && _refreshing) return;
      _requestId++;
      _refreshing = true;
      if (changed) _hasLoaded = false;
      emit(
        _hasLoaded
            ? state.copyWith(
                isRefreshing: true,
                isLoadingMore: false,
                isLoadMoreError: false,
              )
            : RecordsState(search: event.search.trim(), filter: event.filter),
      );
    }
    final requestId = _requestId;
    final result = await loadRecords(
      search: event.search.trim(),
      offset: event.offset,
      filter: event.filter,
    );
    if (emit.isDone || requestId != _requestId) return;
    _refreshing = false;
    switch (result) {
      case Success<RecordsPageData>(data: final page):
        _hasLoaded = true;
        emit(
          RecordsState(
            items: List.unmodifiable(
              more ? [...state.items, ...page.items] : page.items,
            ),
            total: page.total,
            hasMore: page.hasMore && page.items.isNotEmpty,
            isInitialLoading: false,
            search: event.search.trim(),
            filter: event.filter,
          ),
        );
      case ResultFailure<RecordsPageData>(failure: final failure):
        emit(
          _hasLoaded
              ? state.copyWith(
                  isRefreshing: false,
                  isLoadingMore: false,
                  isLoadMoreError: more,
                  error: failure.message,
                )
              : RecordsState(
                  isInitialLoading: false,
                  search: event.search.trim(),
                  filter: event.filter,
                  error: failure.message,
                ),
        );
    }
  }
}
