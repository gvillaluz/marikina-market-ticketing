import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/bloc/ticket_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/bloc/ticket_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/bloc/ticket_state.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_list_header.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_list_section.dart';

class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key});
  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  TicketStatus? _selectedTicketStatus = TicketStatus.pending;
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

  void _load({int offset = 0}) => context.read<TicketBloc>().add(
    LoadTicketSummary(
      search: _searchController.text.trim(),
      offset: offset,
      status: _selectedTicketStatus,
    ),
  );

  void _onScroll() {
    if (!_scrollController.hasClients ||
        (_debouncer?.isActive ?? false) ||
        _scrollController.position.extentAfter >
            AppTheme.ticketPageAheadExtent) {
      return;
    }
    final state = context.read<TicketBloc>().state;
    if (state is TicketsLoaded &&
        state.hasMore &&
        !state.isRefreshing &&
        !state.isLoadingMore &&
        state.errorMessage == null) {
      _load(offset: state.ticketSummary.length);
    }
  }

  void _onSearchChanged(String value) {
    _debouncer?.cancel();
    _debouncer = Timer(AppTheme.ticketSearchDelay, _load);
  }

  void _submitSearch() {
    _debouncer?.cancel();
    _load();
  }

  void _handleChangeStatus(TicketStatus? type) {
    if (type == _selectedTicketStatus) return;
    _debouncer?.cancel();
    setState(() => _selectedTicketStatus = type);
    _load();
  }

  void _retry() {
    _debouncer?.cancel();
    final state = context.read<TicketBloc>().state;
    _load(
      offset: state is TicketsLoaded && state.isLoadMoreError
          ? state.ticketSummary.length
          : 0,
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: RefreshIndicator(
      onRefresh: () {
        _debouncer?.cancel();
        return context.read<TicketBloc>().refreshTickets(
          search: _searchController.text.trim(),
          status: _selectedTicketStatus,
        );
      },
      child: CustomScrollView(
        key: const PageStorageKey('tickets'),
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: AppTheme.ticketHeaderPadding,
            sliver: SliverToBoxAdapter(
              child: TicketListHeader(
                searchController: _searchController,
                selectedStatus: _selectedTicketStatus,
                onSearchChanged: _onSearchChanged,
                onSearchSubmitted: _submitSearch,
                onStatusChanged: _handleChangeStatus,
              ),
            ),
          ),
          TicketListSection(onRetry: _retry),
          const SliverToBoxAdapter(child: SizedBox(height: AppTheme.ticketGap)),
        ],
      ),
    ),
  );
}
