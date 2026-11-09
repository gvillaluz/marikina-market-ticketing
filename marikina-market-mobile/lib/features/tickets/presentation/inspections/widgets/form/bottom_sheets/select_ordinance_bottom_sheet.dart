import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_primary_btn.dart';
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
    context.read<InspectionBloc>().add(
      LoadOrdinanceSelection(personId: widget.personId),
    );
  }

  static bool _matches(Ordinance ordinance, String query) => [
    ordinance.ordinanceNo,
    ordinance.series,
    ordinance.section ?? '',
    ordinance.title,
  ].any((text) => text.toLowerCase().contains(query));

  Widget _tile(
    Ordinance ordinance,
    Set<int> selectedIds,
    String keyPrefix,
  ) => SelectionSheetTile(
    key: ValueKey('$keyPrefix-${ordinance.id}'),
    title: 'Ord No. ${ordinance.ordinanceNo}, Series of ${ordinance.series}',
    subtitle:
        '${ordinance.sectionLabel} · ${ordinance.categoryLabel}\n${ordinance.title}',
    isSelected: selectedIds.contains(ordinance.id),
    onTap: _confirming ? null : () => _toggle(ordinance),
  );

  Widget _groupHeading(String text) => Padding(
    padding: const EdgeInsets.only(top: AppTheme.inspectionSmallGap),
    child: Text(text, style: AppTheme.inspectionHeadingStyle),
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmSelection() {
    if (_confirming || _selectedOrdinances.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _confirming = true;
      _conflictMessage = null;
    });
    final ids = _selectedOrdinances.map((ordinance) => ordinance.id).toList();
    context.read<InspectionBloc>().add(
      widget.isWarningTicket
          ? WarningOrdinanceCheckRequested(
              ids,
              widget.vendorId,
              personId: widget.personId,
            )
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
        if (state.ordinances.isNotEmpty) {
          setState(() {
            _confirming = false;
            _conflictMessage =
                'This person has already received a lifetime warning for this ordinance. Change the selection.';
          });
          return;
        }
        widget.onChanged(List.of(_selectedOrdinances));
        Navigator.pop(context);
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
      final bloc = context.read<InspectionBloc>();
      final available = bloc.ordinances
          .where(
            (ordinance) =>
                ordinance.isActive &&
                (!widget.isWarningTicket || ordinance.warningEligible == true),
          )
          .toList();
      final ordinances = available
          .where((ordinance) => _matches(ordinance, query))
          .toList();
      final selectedIds = _selectedOrdinances
          .map((ordinance) => ordinance.id)
          .toSet();
      final byId = {for (final ordinance in available) ordinance.id: ordinance};
      final shortcuts = bloc.ordinanceShortcuts;
      final groups = query.isNotEmpty || shortcuts == null
          ? const <(String, List<Ordinance>)>[]
          : [
                  (
                    "This person's past violations",
                    shortcuts.personOrdinanceIds,
                  ),
                  ('My recent', shortcuts.myRecentOrdinanceIds),
                  (
                    'Most violated (last 30 days)',
                    shortcuts.mostViolatedOrdinanceIds,
                  ),
                ]
                .map(
                  (group) => (group.$1, [for (final id in group.$2) ?byId[id]]),
                )
                .where((group) => group.$2.isNotEmpty)
                .toList();
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
            ? 'Choose one eligible ordinance for this warning.'
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
                      labelText: 'Search section, title or number',
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
          else ...[
            if (groups.isNotEmpty)
              SliverPadding(
                padding: AppTheme.selectionSheetPadding,
                sliver: SliverList.list(
                  children: [
                    for (final (heading, items) in groups) ...[
                      _groupHeading(heading),
                      for (final ordinance in items)
                        _tile(ordinance, selectedIds, heading),
                    ],
                    _groupHeading('All ordinances'),
                  ],
                ),
              ),
            SliverPadding(
              padding: AppTheme.selectionSheetPadding,
              sliver: SliverList.builder(
                itemCount: ordinances.length,
                itemBuilder: (context, index) =>
                    _tile(ordinances[index], selectedIds, 'all'),
              ),
            ),
          ],
        ],
        footer: AppPrimaryButton(
          label: 'Confirm selection',
          iconData: Icons.check,
          isLoading: _confirming,
          onPressed:
              _selectedOrdinances.isEmpty ||
                  loading ||
                  state is OrdinanceSelectionError
              ? null
              : _confirmSelection,
        ),
      );
    },
  );
}
