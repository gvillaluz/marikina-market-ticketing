import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ordinance.dart';
import 'highlighted_text.dart';
import 'selection_card.dart';
import 'selection_chip.dart';

class OrdinanceCard extends StatelessWidget {
  final Ordinance ordinance;
  final String query;
  final bool isSelected;
  final VoidCallback? onTap;

  const OrdinanceCard({
    required this.ordinance,
    required this.query,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) => SelectionCard(
    isSelected: isSelected,
    onTap: onTap,
    title: HighlightedText(
      text: 'Ord No. ${ordinance.ordinanceNo}, Series of ${ordinance.series}',
      query: query,
      style: AppTheme.cardHeadingStyle,
    ),
    children: [
      Wrap(
        spacing: AppTheme.selectionChipGap,
        runSpacing: AppTheme.selectionChipGap,
        children: [
          SelectionChip(text: ordinance.sectionLabel),
          SelectionChip(text: ordinance.categoryLabel, isAccent: true),
        ],
      ),
      const SizedBox(height: AppTheme.inspectionSmallGap),
      HighlightedText(
        text: ordinance.title,
        query: query,
        style: AppTheme.inspectionBodyStyle,
      ),
    ],
  );
}
