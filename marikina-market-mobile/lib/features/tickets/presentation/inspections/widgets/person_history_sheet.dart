import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/person_ticket_history.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';

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
      child: ListView(
        padding: AppTheme.ticketDetailPadding,
        children: [
          Text(
            'Person citation history',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text('${widget.name} · Person ${widget.personId}'),
          const Text(
            'Citations across businesses and issuing officers. Warnings are excluded.',
          ),
          for (final ticket in _items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Paper reference: ${ticket.paperReference ?? 'Unavailable (legacy record)'} · ${ticket.businessSnapshot?.businessName ?? 'Historical business details unavailable.'}',
              ),
              subtitle: Text(
                'System control: ${ticket.reference}\nIssue place: ${ticket.issuePlace ?? 'Unavailable (legacy record)'}\nRecorded violator: ${ticket.paperViolatorName ?? 'Unconfirmed'}\n${ticket.ordinances.join('; ')}\n${ticket.issuedAt.toLocal()} · ${ticket.status ?? 'Unknown'}\nOfficer: ${ticket.enforcerName}\nAssessed cash: ${ticket.assessedCashFine?.toStringAsFixed(2) ?? 'Not cash'} · Outstanding cash: ${ticket.outstandingCashFine.toStringAsFixed(2)}',
              ),
            ),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (!_loading && _items.isEmpty && _error == null)
            const Text('No citations linked to this person.'),
          if (_error != null) ...[
            Text(_error!),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
          if (_hasMore && !_loading)
            TextButton(onPressed: _load, child: const Text('Load more')),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, !_loading && _error == null),
            child: const Text('Close'),
          ),
        ],
      ),
    ),
  );
}
