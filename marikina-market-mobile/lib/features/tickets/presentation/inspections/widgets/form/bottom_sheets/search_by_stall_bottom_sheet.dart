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

class SearchByBusinessAccountNumberBottomSheet extends StatefulWidget {
  const SearchByBusinessAccountNumberBottomSheet({super.key});
  @override
  State<SearchByBusinessAccountNumberBottomSheet> createState() =>
      _SearchByBusinessAccountNumberBottomSheetState();
}

class _SearchByBusinessAccountNumberBottomSheetState
    extends State<SearchByBusinessAccountNumberBottomSheet> {
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
    context.read<InspectionBloc>().add(SearchByStallNumberRequested(_query));
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

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<InspectionBloc, InspectionState>(
    builder: (context, state) {
      final loading = _isDebouncing || state is InspectionSearchLoading;
      final vendors =
          !loading && _query.isNotEmpty && state is InspectionSearchList
          ? state.vendorList
          : const <VendorSummary>[];
      final selected = _selectedVendor;
      final canSelect =
          selected != null && vendors.any((vendor) => vendor.id == selected.id);
      Widget? message;
      if (_query.isEmpty) {
        message = const SelectionSheetMessage(
          message: 'Enter a Business Account Number to find matching vendors.',
          icon: Icons.storefront_outlined,
        );
      } else if (loading) {
        message = const SelectionSheetMessage(
          message: 'Searching for vendors…',
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
          message:
              'No vendors found. Check the Business Account Number and try again.',
          icon: Icons.search_off,
        );
      }
      return InspectionSelectionSheet(
        title: 'Search by Business Account Number',
        description:
            'Find the Business Account Number on the business permit, then choose a vendor.',
        slivers: [
          SliverPadding(
            padding: AppTheme.selectionSheetPadding,
            sliver: SliverToBoxAdapter(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onSubmitted: (_) => _search(),
                textInputAction: TextInputAction.search,
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                decoration: InputDecoration(
                  labelText: 'Business Account Number',
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
          else
            SliverPadding(
              padding: AppTheme.selectionSheetPadding,
              sliver: SliverList.builder(
                itemCount: vendors.length,
                itemBuilder: (context, index) {
                  final vendor = vendors[index];
                  return SelectionSheetTile(
                    key: ValueKey(vendor.id),
                    title: vendor.tradeName,
                    subtitle: '${vendor.firstName} ${vendor.lastName}',
                    isSelected: selected?.id == vendor.id,
                    onTap: () => setState(() => _selectedVendor = vendor),
                  );
                },
              ),
            ),
        ],
        footer: AppPrimaryButton(
          label: 'Select vendor',
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
