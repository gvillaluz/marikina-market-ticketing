import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import '../../domain/enums/records_filter.dart';
import '../bloc/records/records_bloc.dart';
import '../bloc/records/load_records.dart';
import '../widgets/records_header.dart';
import '../widgets/records_list_section.dart';

class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});
  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  RecordsFilter _filter = RecordsFilter.all;
  Timer? _debounce;
  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _load({int offset = 0}) => context.read<RecordsBloc>().add(
    LoadRecords(search: _search.text.trim(), filter: _filter, offset: offset),
  );
  void _onScroll() {
    if (!_scroll.hasClients ||
        _scroll.position.pixels <= 0 ||
        _scroll.position.extentAfter > 0 ||
        (_debounce?.isActive ?? false)) {
      return;
    }
    _loadMore();
  }

  void _loadMore() {
    final state = context.read<RecordsBloc>().state;
    if (state.hasMore &&
        !state.isInitialLoading &&
        !state.isLoadingMore &&
        !state.isRefreshing &&
        state.error == null) {
      _load(offset: state.items.length);
    }
  }

  void _submit() {
    _debounce?.cancel();
    _resetScroll();
    _load();
  }

  void _resetScroll() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _searchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(AppTheme.inspectionSearchDelay, _submit);
  }

  void _changeFilter(RecordsFilter value) {
    if (value == _filter) return;
    _debounce?.cancel();
    setState(() => _filter = value);
    _resetScroll();
    _load();
  }

  void _retry() {
    _debounce?.cancel();
    final state = context.read<RecordsBloc>().state;
    final sameQuery =
        state.search == _search.text.trim() && state.filter == _filter;
    _load(offset: sameQuery && state.isLoadMoreError ? state.items.length : 0);
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppTheme.recordsBackground,
    child: SafeArea(
      child: RefreshIndicator(
        onRefresh: () {
          _debounce?.cancel();
          return context.read<RecordsBloc>().refreshRecords(
            _search.text.trim(),
            _filter,
          );
        },
        child: CustomScrollView(
          key: const PageStorageKey('vendor_records'),
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: AppTheme.recordsPagePadding,
              sliver: SliverToBoxAdapter(
                child: RecordsHeader(
                  searchController: _search,
                  filter: _filter,
                  onFilterChanged: _changeFilter,
                  onSearchChanged: _searchChanged,
                  onSearchSubmitted: _submit,
                  onClear: () {
                    _search.clear();
                    _submit();
                  },
                ),
              ),
            ),
            RecordsListSection(onRetry: _retry, onLoadMore: _loadMore),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppTheme.inspectionGap),
            ),
          ],
        ),
      ),
    ),
  );
}
