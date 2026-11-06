import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/person_candidate.dart';
import 'person_history_sheet.dart';

// One person with their ticket totals across all businesses.
class PersonRecordTile extends StatelessWidget {
  final PersonCandidate person;
  final List<String> details;
  final String actionLabel;
  final VoidCallback? onAction;

  const PersonRecordTile({
    required this.person,
    required this.details,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  static final _peso = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

  static String _count(int count, String word) =>
      '$count ${count == 1 ? word : '${word}s'}';

  @override
  Widget build(BuildContext context) {
    final totals = person.ticketTotals;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(person.fullName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_count(totals.offenseCount, 'offense')} · '
            '${_count(totals.warningCount, 'warning')} · '
            '${_peso.format(totals.outstandingFine)} unpaid',
          ),
          for (final line in details) Text(line),
        ],
      ),
      trailing: TextButton(onPressed: onAction, child: Text(actionLabel)),
      onTap: () => PersonHistorySheet.show(context, person.id, person.fullName),
    );
  }
}
