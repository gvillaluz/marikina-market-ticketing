import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class SelectionSheetTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback? onTap;

  const SelectionSheetTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: AppTheme.selectionSheetItemPadding,
      child: Material(
        color: isSelected ? colors.primaryContainer : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.controlRadius,
          side: BorderSide(
            color: isSelected ? colors.primary : colors.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          selected: isSelected,
          selectedColor: colors.onPrimaryContainer,
          onTap: onTap,
          title: Text(
            title,
            style: AppTheme.inspectionBodyStyle.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(subtitle),
          trailing: Icon(
            isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
          ),
        ),
      ),
    );
  }
}
