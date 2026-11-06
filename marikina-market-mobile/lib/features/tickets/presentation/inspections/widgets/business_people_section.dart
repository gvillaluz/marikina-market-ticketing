import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/utils/date_formatter_util.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/person_candidate.dart';
import 'person_record_tile.dart';

// The registered owner and the people already ticketed at this business.
class BusinessPeopleSection extends StatelessWidget {
  final String ownerName;
  final List<PersonCandidate> people;
  final bool loading;
  final String? error;
  final int? selectedId;
  final VoidCallback onFindOwner;
  final VoidCallback onRetry;
  final ValueChanged<PersonCandidate> onSelect;

  const BusinessPeopleSection({
    required this.ownerName,
    required this.people,
    required this.loading,
    required this.error,
    required this.selectedId,
    required this.onFindOwner,
    required this.onRetry,
    required this.onSelect,
    super.key,
  });

  static List<String> _lastTicket(PersonCandidate person) {
    final at = person.ticketTotals.lastTicketAt;
    if (at == null) return const [];
    final business = person.ticketTotals.lastBusinessName;
    return [
      'Last ticket: ${DateTimeFormatter.getShortDate(at)}'
          '${business == null ? '' : ' at $business'}',
    ];
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'People at this business',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('Owner: $ownerName'),
        subtitle: const Text('Registered owner of this business.'),
        trailing: TextButton(
          onPressed: onFindOwner,
          child: const Text('Find owner'),
        ),
      ),
      if (loading)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppTheme.ticketSmallGap),
          child: LinearProgressIndicator(
            semanticsLabel: 'Loading people at this business',
          ),
        )
      else if (error != null) ...[
        Text(error!),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(onPressed: onRetry, child: const Text('Retry')),
        ),
      ] else if (people.isEmpty)
        const Text('No one has been ticketed at this business yet.')
      else
        for (final person in people)
          PersonRecordTile(
            key: ValueKey('business-person-${person.id}'),
            person: person,
            details: _lastTicket(person),
            actionLabel: selectedId == person.id ? 'Selected' : 'Select',
            onAction: () => onSelect(person),
          ),
      const SizedBox(height: AppTheme.ticketSmallGap),
    ],
  );
}
