import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

// The shell of a pick-one-or-more card in a selection sheet: a title with a
// check circle, then [children]. A null [onTap] locks the card. A card that
// only shows a choice already made sets [isButton] to false, so screen
// readers do not call it a disabled button.
class SelectionCard extends StatelessWidget {
  final Widget title;
  final List<Widget> children;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool isButton;

  const SelectionCard({
    required this.title,
    required this.children,
    required this.isSelected,
    required this.onTap,
    this.isButton = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: AppTheme.selectionSheetItemPadding,
      child: MergeSemantics(
        child: Semantics(
          button: isButton,
          enabled: isButton ? onTap != null : null,
          selected: isSelected,
          child: Material(
            color: isSelected ? colors.primaryContainer : colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: AppTheme.controlRadius,
              side: BorderSide(
                color: isSelected ? colors.primary : colors.outlineVariant,
                width: isSelected
                    ? AppTheme.selectionCardSelectedBorderWidth
                    : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: AppTheme.selectionCardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: title),
                        const SizedBox(width: AppTheme.inspectionSmallGap),
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: isSelected ? colors.primary : colors.outline,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.inspectionSmallGap),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
