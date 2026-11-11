import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/person_candidate.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import 'create_person_sheet.dart';
import 'form/bottom_sheets/inspection_selection_sheet.dart';
import 'form/bottom_sheets/selection_sheet_message.dart';
import 'person_result_card.dart';

// Finds the violator by name as it is typed. Tapping a person returns them.
// For a registered business, the people already ticketed there are listed
// before typing and come first in the results.
class FindPersonSheet extends StatefulWidget {
  // Null for an unregistered vendor: nobody is listed before typing.
  final int? businessId;
  const FindPersonSheet({required this.businessId, super.key});
  @override
  State<FindPersonSheet> createState() => _FindPersonSheetState();
}

class _FindPersonSheetState extends State<FindPersonSheet> {
  static const _minSearchLength = 2;
  final _searchController = TextEditingController();
  Timer? _debouncer;
  String _query = '';
  bool _searching = false, _loadingMore = false, _hasMore = false;
  String? _searchError;
  final List<PersonCandidate> _results = [];
  List<PersonCandidate> _people = const [];
  bool _peopleLoading = false;
  String? _peopleError;

  bool get _canSearch => _query.length >= _minSearchLength;

  @override
  void initState() {
    super.initState();
    if (widget.businessId != null) {
      _peopleLoading = true;
      _loadPeople();
    }
  }

  @override
  void dispose() {
    _debouncer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadPeople() => context.read<InspectionBloc>().add(
    BusinessPeopleRequested(widget.businessId!),
  );

  void _search({int offset = 0}) {
    _debouncer?.cancel();
    setState(() {
      // A fresh search starts from page 1, so a failure shows on its own
      // and Try again redoes the whole search.
      if (offset == 0) {
        _results.clear();
        _hasMore = false;
      }
      _searching = offset == 0;
      _loadingMore = offset > 0;
      _searchError = null;
    });
    context.read<InspectionBloc>().add(
      PersonMatchesRequested(_query, offset: offset),
    );
  }

  void _onSearchChanged(String value) {
    _debouncer?.cancel();
    context.read<InspectionBloc>().invalidatePersonSearch();
    setState(() {
      _query = value.trim();
      _results.clear();
      _hasMore = false;
      _loadingMore = false;
      _searchError = null;
      _searching = _canSearch;
    });
    if (_canSearch) {
      _debouncer = Timer(AppTheme.inspectionSearchDelay, () {
        if (mounted) _search();
      });
    }
  }

  void _choose(PersonCandidate person) {
    FocusScope.of(context).unfocus();
    Navigator.pop(context, person);
  }

  Future<void> _addNewPerson() async {
    final person = await showModalBottomSheet<PersonCandidate>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: context.read<InspectionBloc>(),
        child: CreatePersonSheet(name: _searchController.text.trim()),
      ),
    );
    if (!mounted) return;
    if (person != null) {
      _choose(person);
    } else if (_canSearch) {
      // A failed save may still have gone through: show the records again.
      _search();
    }
  }

  void _onState(BuildContext context, InspectionState state) {
    if (state is BusinessPeopleLoading) {
      setState(() {
        _peopleLoading = true;
        _peopleError = null;
      });
    }
    if (state is BusinessPeopleLoaded) {
      setState(() {
        _peopleLoading = false;
        _people = state.people;
      });
    }
    if (state is BusinessPeopleError) {
      setState(() {
        _peopleLoading = false;
        _peopleError = state.message;
      });
    }
    if (state is PersonMatchesLoaded && state.name == _query) {
      setState(() {
        _searching = false;
        _loadingMore = false;
        _hasMore = state.page.hasMore;
        if (state.offset == 0) _results.clear();
        _results.addAll(state.page.items);
      });
    }
    if (state is PersonMatchesError) {
      setState(() {
        _searching = false;
        _loadingMore = false;
        _searchError = state.message;
      });
    }
  }

  Widget? _message() {
    if (!_canSearch) {
      if (_peopleLoading) {
        return const SelectionSheetMessage(
          message: 'Loading people…',
          isLoading: true,
        );
      }
      if (_peopleError != null) {
        return SelectionSheetMessage(
          message: _peopleError!,
          icon: Icons.error_outline,
          onRetry: _loadPeople,
        );
      }
      if (_people.isEmpty) {
        return const SelectionSheetMessage(
          message: 'Type the name to search.',
          icon: Icons.person_search_outlined,
        );
      }
      return null;
    }
    if (_searching) {
      return const SelectionSheetMessage(
        message: 'Searching…',
        isLoading: true,
      );
    }
    if (_results.isEmpty && _searchError != null) {
      return SelectionSheetMessage(
        message: _searchError!,
        icon: Icons.error_outline,
        onRetry: _search,
      );
    }
    if (_results.isEmpty) {
      return const SelectionSheetMessage(
        message: 'No match. Check the spelling or add a new person.',
        icon: Icons.search_off,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hereIds = {for (final person in _people) person.id};
    final shown = _canSearch
        ? [
            ..._results.where((person) => hereIds.contains(person.id)),
            ..._results.where((person) => !hereIds.contains(person.id)),
          ]
        : _people;
    final message = _message();
    return BlocListener<InspectionBloc, InspectionState>(
      listener: _onState,
      child: InspectionSelectionSheet(
        title: 'Find violator',
        description: 'Tap a person to choose.',
        slivers: [
          SliverPadding(
            padding: AppTheme.selectionSheetPadding,
            sliver: SliverToBoxAdapter(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onSubmitted: (_) {
                  if (_canSearch) _search();
                },
                maxLength: 200,
                textInputAction: TextInputAction.search,
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                decoration: const InputDecoration(
                  hintText: 'Type the name',
                  counterText: '',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
          ),
          if (message != null)
            SliverFillRemaining(hasScrollBody: false, child: message)
          else ...[
            SliverPadding(
              padding: AppTheme.selectionSheetPadding.copyWith(top: 0),
              sliver: SliverList.builder(
                itemCount: shown.length,
                itemBuilder: (context, index) {
                  final person = shown[index];
                  return PersonResultCard(
                    key: ValueKey(person.id),
                    person: person,
                    query: _canSearch ? _query : '',
                    isTicketedHere: hereIds.contains(person.id),
                    onTap: () => _choose(person),
                  );
                },
              ),
            ),
            // Loading more failed: the people already shown stay.
            if (_searchError != null)
              SliverToBoxAdapter(
                child: SelectionSheetMessage(
                  message: _searchError!,
                  icon: Icons.error_outline,
                  onRetry: () => _search(offset: _results.length),
                ),
              )
            else if (_canSearch && _hasMore)
              SliverPadding(
                padding: AppTheme.selectionSheetPadding.copyWith(top: 0),
                sliver: SliverToBoxAdapter(
                  child: TextButton(
                    onPressed: _loadingMore
                        ? null
                        : () => _search(offset: _results.length),
                    child: Text(_loadingMore ? 'Loading…' : 'More results'),
                  ),
                ),
              ),
          ],
        ],
        footer: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addNewPerson,
            icon: const Icon(Icons.person_add_alt),
            label: const Text('Not listed? Add new person'),
          ),
        ),
      ),
    );
  }
}
