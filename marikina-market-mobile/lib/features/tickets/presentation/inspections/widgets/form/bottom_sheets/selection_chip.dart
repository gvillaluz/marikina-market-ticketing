import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'highlighted_text.dart';

// A small tag on a selection card, such as "Stall 12" or "Section 69".
class SelectionChip extends StatelessWidget {
  final String text;
  final String prefix;
  final String query;
  final bool isAccent;

  const SelectionChip({
    required this.text,
    this.prefix = '',
    this.query = '',
    this.isAccent = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: AppTheme.selectionChipPadding,
      decoration: BoxDecoration(
        color: isAccent ? AppColors.tertiary : colors.surface,
        borderRadius: AppTheme.selectionChipRadius,
        border: Border.all(
          color: isAccent ? AppColors.tertiary : colors.outlineVariant,
        ),
      ),
      child: HighlightedText(
        prefix: prefix,
        text: text,
        query: query,
        style: AppTheme.inspectionCaptionStyle.copyWith(
          color: isAccent ? colors.primary : colors.onSurface,
        ),
      ),
    );
  }
}
