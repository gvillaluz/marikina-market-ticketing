import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import '../../domain/enums/records_filter.dart';

class RecordsHeader extends StatelessWidget {
  final TextEditingController searchController;
  final RecordsFilter filter;
  final ValueChanged<RecordsFilter> onFilterChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchSubmitted, onClear;
  const RecordsHeader({
    required this.searchController,
    required this.filter,
    required this.onFilterChanged,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onClear,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'My Records',
          style: AppTheme.profileHeadingStyle.copyWith(color: colors.primary),
        ),
        const SizedBox(height: AppTheme.inspectionTinyGap),
        Text(
          'View your recorded warnings and violation tickets.',
          style: AppTheme.recordsBodyStyle.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppTheme.inspectionSmallGap),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.recordsFilterBackground,
            borderRadius: AppTheme.controlRadius,
          ),
          child: Padding(
            padding: AppTheme.recordsFilterPadding,
            child: Row(
              children: [
                for (final option in RecordsFilter.values)
                  Expanded(
                    child: TextButton(
                      onPressed: () => onFilterChanged(option),
                      style: TextButton.styleFrom(
                        backgroundColor: filter == option
                            ? colors.primary
                            : null,
                        foregroundColor: filter == option
                            ? colors.onPrimary
                            : colors.primary,
                        padding: AppTheme.recordsFilterButtonPadding,
                        textStyle: AppTheme.recordsBodyStyle,
                      ),
                      child: Semantics(
                        selected: filter == option,
                        child: Text(option.label, textAlign: TextAlign.center),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.inspectionSmallGap),
        TextField(
          controller: searchController,
          maxLength: 200,
          textInputAction: TextInputAction.search,
          onChanged: onSearchChanged,
          onSubmitted: (_) => onSearchSubmitted(),
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          decoration: InputDecoration(
            hintText: 'Search control number',
            counterText: '',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: searchController,
              builder: (context, value, _) => value.text.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: onClear,
                      icon: const Icon(Icons.clear),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
