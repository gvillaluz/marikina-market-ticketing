import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/vendor_summary.dart';
import 'highlighted_text.dart';
import 'selection_card.dart';
import 'selection_chip.dart';

class BusinessResultCard extends StatelessWidget {
  final VendorSummary vendor;
  final String query;
  final bool isSelected;
  final VoidCallback onTap;

  const BusinessResultCard({
    required this.vendor,
    required this.query,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  Widget _line(IconData icon, ColorScheme colors, Widget text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 1),
        child: Icon(
          icon,
          size: AppTheme.inspectionIconSize,
          color: colors.onSurfaceVariant,
        ),
      ),
      const SizedBox(width: AppTheme.inspectionSmallGap),
      Expanded(child: text),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SelectionCard(
      isSelected: isSelected,
      onTap: onTap,
      title: HighlightedText(
        text: vendor.tradeName,
        query: query,
        style: AppTheme.cardHeadingStyle,
      ),
      children: [
        Wrap(
          spacing: AppTheme.selectionChipGap,
          runSpacing: AppTheme.selectionChipGap,
          children: [
            if (vendor.stallNumber != null)
              SelectionChip(
                prefix: 'Stall ',
                text: vendor.stallNumber!,
                query: query,
              ),
            SelectionChip(text: vendor.marketSectionName, query: query),
            SelectionChip(
              text: vendor.type.value,
              query: query,
              isAccent: true,
            ),
          ],
        ),
        const SizedBox(height: AppTheme.inspectionSmallGap),
        _line(
          Icons.person_outline,
          colors,
          HighlightedText(
            text: vendor.ownerName,
            query: query,
            style: AppTheme.inspectionBodyStyle,
          ),
        ),
        const SizedBox(height: AppTheme.inspectionTinyGap),
        _line(
          Icons.place_outlined,
          colors,
          HighlightedText(
            text: vendor.address,
            query: query,
            style: AppTheme.inspectionBodyStyle.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.inspectionSmallGap),
        HighlightedText(
          prefix: 'Account ',
          text: vendor.businessAccountNumber,
          query: query,
          style: AppTheme.captionTextStyle.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
