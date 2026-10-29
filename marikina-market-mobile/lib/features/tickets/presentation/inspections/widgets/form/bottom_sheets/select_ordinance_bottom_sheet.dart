import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_primary_btn.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ordinance.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import 'inspection_selection_sheet.dart';
import 'selection_sheet_message.dart';
import 'selection_sheet_tile.dart';

class SelectOrdinanceBottomSheet extends StatefulWidget {
  final bool isWarningTicket;
  final List<Ordinance> ordinances;
  final ValueChanged<List<Ordinance>> onChanged;
  final int? vendorId;
  final int? personId;
  const SelectOrdinanceBottomSheet({
    required this.isWarningTicket,
    required this.ordinances,
    required this.onChanged,
    required this.vendorId,
    this.personId,
    super.key,
  });
  @override
  State<SelectOrdinanceBottomSheet> createState() =>
      _SelectOrdinanceBottomSheetState();
}

class _SelectOrdinanceBottomSheetState
    extends State<SelectOrdinanceBottomSheet> {
  late final List<Ordinance> _selectedOrdinances;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _conflictMessage;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _selectedOrdinances = List.of(widget.ordinances);
    context.read<InspectionBloc>().add(LoadOrdinanceSelection());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmSelection() {
    if (_confirming || _selectedOrdinances.isEmpty || widget.vendorId == null) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _confirming = true;
      _conflictMessage = null;
    });
    final ids = _selectedOrdinances.map((ordinance) => ordinance.id).toList();
    context.read<InspectionBloc>().add(
      widget.isWarningTicket
          ? WarningOrdinanceCheckRequested(ids, widget.vendorId!)
          : FineSummaryRequested(
              ids,
              widget.vendorId,
              personId: widget.personId,
            ),
    );
  }

  void _toggle(Ordinance ordinance) {
    setState(() {
      _conflictMessage = null;
      if (_selectedOrdinances.any((selected) => selected.id == ordinance.id)) {
        _selectedOrdinances.removeWhere(
          (selected) => selected.id == ordinance.id,
        );
      } else if (widget.isWarningTicket && _selectedOrdinances.isNotEmpty) {
        _conflictMessage =
            'Warnings can only have one ordinance. Remove the current selection first.';
      } else {
        _selectedOrdinances.add(ordinance);
      }
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<InspectionBloc, InspectionState>(
    listener: (context, state) {
      if (state is FineSummaryLoaded) {
        if (state.summary.breakdownItems.any((item) => item.isDuplicate)) {
          setState(() {
            _confirming = false;
            _conflictMessage =
                'This person already has an active citation for a selected ordinance today. Change the selection and verify again.';
          });
          return;
        }
        widget.onChanged(List.of(_selectedOrdinances));
        Navigator.pop(context, state.summary);
      } else if (state is WarningOrdinanceCheckLoaded) {
        final warningIds = state.ordinances
            .map((ordinance) => ordinance.ordinanceId)
            .toSet();
        _selectedOrdinances.removeWhere(
          (ordinance) => warningIds.contains(ordinance.id),
        );
        widget.onChanged(List.of(_selectedOrdinances));
        Navigator.pop(context, state.ordinances);
      } else if (state is FineSummaryError ||
          state is FineSummaryNetworkError ||
          state is WarningOrdinanceCheckError) {
        setState(() {
          _confirming = false;
          _conflictMessage = switch (state) {
            FineSummaryError() => state.message,
            FineSummaryNetworkError() => state.message,
            WarningOrdinanceCheckError() => state.message,
            _ => null,
          };
        });
      }
    },
    builder: (context, state) {
      final query = _searchQuery.toLowerCase();
      final ordinances = context
          .read<InspectionBloc>()
          .ordinances
          .where(
            (ordinance) =>
                (!widget.isWarningTicket ||
                    ordinance.severity == Severity.minor) &&
                (ordinance.ordinanceNo.toLowerCase().contains(query) ||
                    ordinance.series.toLowerCase().contains(query)),
          )
          .toList();
      final selectedIds = _selectedOrdinances
          .map((ordinance) => ordinance.id)
          .toSet();
      final loading =
          state is OrdinanceSelectionLoading || state is InspectionInitial;
      Widget? message;
      if (loading) {
        message = const SelectionSheetMessage(
          message: 'Loading ordinances…',
          isLoading: true,
        );
      } else if (state is OrdinanceSelectionError) {
        message = SelectionSheetMessage(
          message: state.message,
          icon: Icons.error_outline,
          onRetry: () =>
              context.read<InspectionBloc>().add(LoadOrdinanceSelection()),
        );
      } else if (ordinances.isEmpty) {
        message = const SelectionSheetMessage(
          message: 'No ordinances match your search.',
          icon: Icons.search_off,
        );
      }
      return InspectionSelectionSheet(
        title: 'Select ordinances',
        description: widget.isWarningTicket
            ? 'Choose one minor ordinance for this warning.'
            : 'Choose the ordinances for this inspection.',
        isBusy: _confirming,
        slivers: [
          SliverPadding(
            padding: AppTheme.selectionSheetPadding,
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _searchController,
                    enabled: !_confirming,
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.trim()),
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    decoration: InputDecoration(
                      labelText: 'Search number or series',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: _confirming
                                  ? null
                                  : () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                              icon: const Icon(Icons.clear),
                            ),
                    ),
                  ),
                  if (_selectedOrdinances.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.inspectionSmallGap),
                    Text(
                      '${_selectedOrdinances.length} selected',
                      style: AppTheme.inspectionCaptionStyle,
                    ),
                    Wrap(
                      spacing: AppTheme.inspectionTinyGap,
                      runSpacing: AppTheme.inspectionTinyGap,
                      children: _selectedOrdinances
                          .map(
                            (ordinance) => InputChip(
                              label: Builder(
                                builder: (context) => DefaultTextStyle(
                                  style: DefaultTextStyle.of(context).style,
                                  child: Text(
                                    'Ord No. ${ordinance.ordinanceNo}, Series of ${ordinance.series}',
                                  ),
                                ),
                              ),
                              onDeleted: _confirming
                                  ? null
                                  : () => _toggle(ordinance),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (_conflictMessage != null) ...[
                    const SizedBox(height: AppTheme.inspectionSmallGap),
                    Text(
                      _conflictMessage!,
                      style: AppTheme.inspectionBodyStyle.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (message != null)
            SliverFillRemaining(hasScrollBody: false, child: message)
          else
            SliverPadding(
              padding: AppTheme.selectionSheetPadding,
              sliver: SliverList.builder(
                itemCount: ordinances.length,
                itemBuilder: (context, index) {
                  final ordinance = ordinances[index];
                  return SelectionSheetTile(
                    key: ValueKey(ordinance.id),
                    title:
                        'Ord No. ${ordinance.ordinanceNo}, Series of ${ordinance.series}',
                    subtitle: ordinance.ordinanceCode,
                    isSelected: selectedIds.contains(ordinance.id),
                    onTap: _confirming ? null : () => _toggle(ordinance),
                  );
                },
              ),
            ),
        ],
        footer: AppPrimaryButton(
          label: 'Confirm selection',
          iconData: Icons.check,
          isLoading: _confirming,
          onPressed:
              _selectedOrdinances.isEmpty ||
                  widget.vendorId == null ||
                  loading ||
                  state is OrdinanceSelectionError
              ? null
              : _confirmSelection,
        ),
      );
    },
  );
}
