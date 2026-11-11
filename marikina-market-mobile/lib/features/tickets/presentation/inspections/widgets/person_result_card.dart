import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/person_candidate.dart';
import 'form/bottom_sheets/highlighted_text.dart';
import 'form/bottom_sheets/selection_card.dart';
import 'form/bottom_sheets/selection_chip.dart';

// One person as a card: the name (typed letters in bold), short tags and the
// address. Tags with nothing to say, such as "0 warnings", are left out.
class PersonResultCard extends StatelessWidget {
  final PersonCandidate person;
  final String query;
  final bool isOwner;
  final bool isTicketedHere;
  final bool isSelected;
  // Null for the chosen violator's card, which only shows the choice.
  final VoidCallback? onTap;

  const PersonResultCard({
    required this.person,
    required this.onTap,
    this.query = '',
    this.isOwner = false,
    this.isTicketedHere = false,
    this.isSelected = false,
    super.key,
  });

  static final _peso = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

  static String _count(int count, String word) =>
      '$count ${count == 1 ? word : '${word}s'}';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final totals = person.ticketTotals;
    final tags = [
      if (isOwner) const SelectionChip(text: 'Owner', isAccent: true),
      if (isTicketedHere)
        const SelectionChip(text: 'Ticketed here', isAccent: true),
      if (totals.offenseCount > 0)
        SelectionChip(text: _count(totals.offenseCount, 'ticket')),
      if (totals.warningCount > 0)
        SelectionChip(text: _count(totals.warningCount, 'warning')),
      if (totals.outstandingFine > 0)
        SelectionChip(text: '${_peso.format(totals.outstandingFine)} unpaid'),
    ];
    return SelectionCard(
      isSelected: isSelected,
      onTap: onTap,
      isButton: onTap != null,
      title: HighlightedText(
        text: person.fullName,
        query: query,
        style: AppTheme.cardHeadingStyle,
      ),
      children: [
        if (tags.isNotEmpty) ...[
          Wrap(
            spacing: AppTheme.selectionChipGap,
            runSpacing: AppTheme.selectionChipGap,
            children: tags,
          ),
          const SizedBox(height: AppTheme.inspectionSmallGap),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.place_outlined,
              size: AppTheme.inspectionIconSize,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: AppTheme.inspectionSmallGap),
            Expanded(
              child: Text(
                person.address,
                style: AppTheme.inspectionBodyStyle.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
