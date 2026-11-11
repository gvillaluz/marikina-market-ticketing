import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_primary_btn.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/vendor_summary.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import 'business_result_card.dart';
import 'inspection_selection_sheet.dart';
import 'selection_sheet_message.dart';

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
          message: 'Start typing to find a business.',
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
        description: 'Search, then tap a business to select it.',
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
                  labelText: 'Search businesses',
                  hintText: 'Name, stall, owner, address or account number',
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
              padding: AppTheme.selectionSheetPadding.copyWith(bottom: 0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  '${vendors.length} ${vendors.length == 1 ? 'business' : 'businesses'} ${results?.hasMore == true ? 'shown' : 'found'}',
                  style: AppTheme.inspectionCaptionStyle.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: AppTheme.selectionSheetPadding.copyWith(
                top: AppTheme.inspectionSmallGap,
              ),
              sliver: SliverList.builder(
                itemCount: vendors.length,
                itemBuilder: (context, index) {
                  final vendor = vendors[index];
                  return BusinessResultCard(
                    key: ValueKey(vendor.id),
                    vendor: vendor,
                    query: _query,
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
