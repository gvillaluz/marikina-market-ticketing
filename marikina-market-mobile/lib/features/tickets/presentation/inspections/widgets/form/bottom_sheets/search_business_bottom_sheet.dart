import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_primary_btn.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/vendor_summary.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import 'inspection_selection_sheet.dart';
import 'selection_sheet_message.dart';
import 'selection_sheet_tile.dart';

class SearchBusinessBottomSheet extends StatefulWidget {
  const SearchBusinessBottomSheet({super.key});
  @override
  State<SearchBusinessBottomSheet> createState() =>
      _SearchBusinessBottomSheetState();
}

class _SearchBusinessBottomSheetState extends State<SearchBusinessBottomSheet> {
  final _searchController = TextEditingController();
  Timer? _debouncer;
  VendorSummary? _selectedVendor;
  String _query = '';
  bool _isDebouncing = false;

  @override
  void dispose() {
    _debouncer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    _debouncer?.cancel();
    setState(() => _isDebouncing = false);
    context.read<InspectionBloc>().add(BusinessSearchRequested(_query));
  }

  void _onSearchChanged(String value) {
    _debouncer?.cancel();
    setState(() {
      _query = value.trim();
      _selectedVendor = null;
      _isDebouncing = _query.isNotEmpty;
    });
    if (_query.isEmpty) {
      _search();
    } else {
      _debouncer = Timer(AppTheme.inspectionSearchDelay, () {
        if (mounted) _search();
      });
    }
  }

  static String _details(VendorSummary vendor) => [
    if (vendor.stallNumber != null) 'Stall ${vendor.stallNumber}',
    vendor.marketSectionName,
    'Owner: ${vendor.ownerName}',
  ].join(' · ');

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<InspectionBloc, InspectionState>(
    builder: (context, state) {
      final loading = _isDebouncing || state is InspectionSearchLoading;
      final results =
          !loading && _query.isNotEmpty && state is InspectionSearchList
          ? state
          : null;
      final vendors = results?.vendorList ?? const <VendorSummary>[];
      final selected = _selectedVendor;
      final canSelect =
          selected != null && vendors.any((vendor) => vendor.id == selected.id);
      Widget? message;
      if (_query.isEmpty) {
        message = const SelectionSheetMessage(
          message:
              'Type a business name, stall number or account number to find the business.',
          icon: Icons.storefront_outlined,
        );
      } else if (loading) {
        message = const SelectionSheetMessage(
          message: 'Searching for businesses…',
          isLoading: true,
        );
      } else if (state is InspectionSearchError) {
        message = SelectionSheetMessage(
          message: state.error,
          icon: Icons.error_outline,
          onRetry: _search,
        );
      } else if (vendors.isEmpty) {
        message = const SelectionSheetMessage(
          message: 'No businesses found. Check the spelling and try again.',
          icon: Icons.search_off,
        );
      }
      return InspectionSelectionSheet(
        title: 'Find business',
        description:
            'Search by business name, stall number or account number, then choose the business.',
        slivers: [
          SliverPadding(
            padding: AppTheme.selectionSheetPadding,
            sliver: SliverToBoxAdapter(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onSubmitted: (_) => _search(),
                maxLength: 200,
                textInputAction: TextInputAction.search,
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                decoration: InputDecoration(
                  labelText: 'Business name, stall number or account number',
                  counterText: '',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        ),
                ),
              ),
            ),
          ),
          if (message != null)
            SliverFillRemaining(hasScrollBody: false, child: message)
          else ...[
            SliverPadding(
              padding: AppTheme.selectionSheetPadding,
              sliver: SliverList.builder(
                itemCount: vendors.length,
                itemBuilder: (context, index) {
                  final vendor = vendors[index];
                  return SelectionSheetTile(
                    key: ValueKey(vendor.id),
                    title: vendor.tradeName,
                    subtitle: _details(vendor),
                    isSelected: selected?.id == vendor.id,
                    onTap: () => setState(() => _selectedVendor = vendor),
                  );
                },
              ),
            ),
            if (results?.hasMore == true)
              const SliverPadding(
                padding: AppTheme.selectionSheetPadding,
                sliver: SliverToBoxAdapter(
                  child: Text('Keep typing to narrow the results.'),
                ),
              ),
          ],
        ],
        footer: AppPrimaryButton(
          label: 'Select business',
          iconData: Icons.check,
          onPressed: canSelect
              ? () {
                  FocusScope.of(context).unfocus();
                  Navigator.pop(context, selected);
                }
              : null,
        ),
      );
    },
  );
}
