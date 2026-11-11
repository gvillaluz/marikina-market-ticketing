import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_outlined_btn.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/person_ticket_history.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import 'person_history_card.dart';
import 'person_history_message.dart';

class PersonHistorySheet extends StatefulWidget {
  final int personId;
  final String name;
  const PersonHistorySheet({
    super.key,
    required this.personId,
    required this.name,
  });
  static Future<bool?> show(BuildContext context, int id, String name) =>
      showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => BlocProvider.value(
          value: context.read<InspectionBloc>(),
          child: PersonHistorySheet(personId: id, name: name),
        ),
      );
  @override
  State<PersonHistorySheet> createState() => _PersonHistorySheetState();
}

class _PersonHistorySheetState extends State<PersonHistorySheet> {
  final List<PersonTicketHistory> _items = [];
  bool _loading = true, _hasMore = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => context.read<InspectionBloc>().add(
    PersonHistoryRequested(widget.personId, offset: _items.length),
  );
  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<InspectionBloc, InspectionState>(
    listener: (context, state) {
      if (state is PersonHistoryLoading) {
        setState(() {
          _loading = true;
          _error = null;
        });
      }
      if (state is PersonHistoryLoaded && state.personId == widget.personId) {
        setState(() {
          _loading = false;
          _hasMore = state.page.hasMore;
          if (state.offset == 0) _items.clear();
          _items.addAll(state.page.items);
        });
      }
      if (state is PersonHistoryError) {
        setState(() {
          _loading = false;
          _error = state.message;
        });
      }
    },
    builder: (context, state) => FractionallySizedBox(
      heightFactor: .85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Person citation history',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(widget.name.trim(), style: AppTheme.ticketHeadingStyle),
                Text(
                  'Citations across businesses and issuing officers. Warnings are excluded.',
                  style: AppTheme.ticketBodyStyle.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final ticket in _items) PersonHistoryCard(ticket: ticket),
                if (_loading && _items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(AppTheme.dashboardSectionGap),
                    child: Center(
                      child: CircularProgressIndicator(
                        semanticsLabel: 'Loading citation history',
                      ),
                    ),
                  ),
                if (!_loading && _items.isEmpty && _error == null)
                  const PersonHistoryMessage(
                    iconData: Icons.history,
                    title: 'No citations yet',
                    message: 'No citations linked to this person.',
                  ),
                if (_error != null)
                  PersonHistoryMessage(
                    iconData: Icons.error_outline,
                    title: 'Could not load the history',
                    message: _error!,
                    isError: true,
                    onRetry: _load,
                  ),
                if (_hasMore && _error == null && _items.isNotEmpty)
                  AppOutlinedBtn(
                    label: 'Load more',
                    iconData: Icons.expand_more,
                    onPressed: _load,
                    isLoading: _loading,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                  ),
              ],
            ),
          ),
          Padding(
            padding: AppTheme.selectionSheetPadding,
            child: AppOutlinedBtn(
              label: 'Close',
              iconData: Icons.close,
              onPressed: () =>
                  Navigator.pop(context, !_loading && _error == null),
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
          ),
        ],
      ),
    ),
  );
}
