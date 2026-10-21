import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/inspection_list_header.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/inspection_list_section.dart';

class InspectionsPage extends StatefulWidget {
  const InspectionsPage({super.key});
  @override
  State<InspectionsPage> createState() => _InspectionsPageState();
}

class _InspectionsPageState extends State<InspectionsPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ViolationType? _selectedViolationType;
  Timer? _debouncer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debouncer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _load({int offset = 0}) => context.read<InspectionBloc>().add(
    LoadInspectionTickets(
      search: _searchController.text.trim(),
      offset: offset,
      type: _selectedViolationType,
    ),
  );

  void _onScroll() {
    if (!_scrollController.hasClients ||
        (_debouncer?.isActive ?? false) ||
        _scrollController.position.extentAfter >
            AppTheme.inspectionPageAheadExtent) {
      return;
    }
    final state = context.read<InspectionBloc>().state;
    if (state is InspectionTicketsLoaded &&
        state.hasMore &&
        !state.isRefreshing &&
        !state.isLoadingMore &&
        state.errorMessage == null) {
      _load(offset: state.ticketSummary.length);
    }
  }

  void _onSearchChanged(String value) {
    _debouncer?.cancel();
    _debouncer = Timer(AppTheme.inspectionSearchDelay, _load);
  }

  void _submitSearch() {
    _debouncer?.cancel();
    _load();
  }

  void _handleChangeType(ViolationType? type) {
    if (type == _selectedViolationType) return;
    _debouncer?.cancel();
    setState(() => _selectedViolationType = type);
    _load();
  }

  void _retry() {
    _debouncer?.cancel();
    final state = context.read<InspectionBloc>().state;
    _load(
      offset: state is InspectionTicketsLoaded && state.isLoadMoreError
          ? state.ticketSummary.length
          : 0,
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: RefreshIndicator(
      onRefresh: () {
        _debouncer?.cancel();
        return context.read<InspectionBloc>().refreshInspections(
          search: _searchController.text.trim(),
          type: _selectedViolationType,
        );
      },
      child: CustomScrollView(
        key: const PageStorageKey('inspections'),
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: AppTheme.inspectionHeaderPadding,
            sliver: SliverToBoxAdapter(
              child: InspectionListHeader(
                searchController: _searchController,
                selectedType: _selectedViolationType,
                onSearchChanged: _onSearchChanged,
                onSearchSubmitted: _submitSearch,
                onTypeChanged: _handleChangeType,
              ),
            ),
          ),
          InspectionListSection(onRetry: _retry),
          const SliverToBoxAdapter(
            child: SizedBox(height: AppTheme.inspectionGap),
          ),
        ],
      ),
    ),
  );
}
