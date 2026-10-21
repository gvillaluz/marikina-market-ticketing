import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_primary_btn.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/filter_row.dart';

class InspectionListHeader extends StatelessWidget {
  final TextEditingController searchController;
  final ViolationType? selectedType;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchSubmitted;
  final ValueChanged<ViolationType?> onTypeChanged;

  const InspectionListHeader({
    required this.searchController,
    required this.selectedType,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onTypeChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Inspections',
        style: AppTheme.inspectionTitleStyle.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      const SizedBox(height: AppTheme.inspectionTinyGap),
      Text(
        'Review and manage issued inspection tickets.',
        style: AppTheme.pageSubtitleStyle.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: AppTheme.inspectionGap),
      AppPrimaryButton(
        label: 'New Inspection',
        iconData: Icons.add,
        onPressed: () => context.pushNamed(Routes.newInspectionName),
      ),
      const SizedBox(height: AppTheme.inspectionGap),
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: searchController,
        builder: (context, value, child) => TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          onSubmitted: (_) => onSearchSubmitted(),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'Search inspections',
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      searchController.clear();
                      onSearchSubmitted();
                    },
                    icon: const Icon(Icons.close),
                  ),
          ),
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
        ),
      ),
      const SizedBox(height: AppTheme.inspectionSmallGap),
      FilterRow(typeSelected: selectedType, onChange: onTypeChanged),
    ],
  );
}
