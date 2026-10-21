import '../../../domain/entities/vendor_record.dart';
import '../../../domain/enums/records_filter.dart';

class RecordsState {
  final List<VendorRecord> items;
  final int total;
  final bool hasMore,
      isInitialLoading,
      isRefreshing,
      isLoadingMore,
      isLoadMoreError;
  final String? error;
  final String search;
  final RecordsFilter filter;
  const RecordsState({
    this.items = const [],
    this.total = 0,
    this.hasMore = false,
    this.isInitialLoading = true,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.isLoadMoreError = false,
    this.error,
    this.search = '',
    this.filter = RecordsFilter.all,
  });
  RecordsState copyWith({
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? isLoadMoreError,
    String? error,
  }) => RecordsState(
    items: items,
    total: total,
    hasMore: hasMore,
    isInitialLoading: isInitialLoading,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    isLoadMoreError: isLoadMoreError ?? this.isLoadMoreError,
    error: error,
    search: search,
    filter: filter,
  );
}
