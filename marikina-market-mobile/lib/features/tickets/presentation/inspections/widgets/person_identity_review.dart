import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/person_candidate.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/vendor_summary.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import 'business_people_section.dart';
import 'create_person_sheet.dart';
import 'person_history_sheet.dart';
import 'person_record_tile.dart';

class PersonIdentityReview extends StatefulWidget {
  // Null when the vendor is not registered: there is no owner or people list.
  final VendorSummary? vendor;
  final void Function(PersonCandidate? person, String paperName) onChanged;
  const PersonIdentityReview({
    super.key,
    required this.vendor,
    required this.onChanged,
  });
  @override
  State<PersonIdentityReview> createState() => _PersonIdentityReviewState();
}

class _PersonIdentityReviewState extends State<PersonIdentityReview> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final List<PersonCandidate> _candidates = [];
  PersonCandidate? _confirmed;
  bool _checked = false, _hasMore = false, _loading = false;
  String? _message;
  List<PersonCandidate> _people = const [];
  bool _peopleLoading = true;
  String? _peopleError;

  @override
  void initState() {
    super.initState();
    if (widget.vendor == null) {
      _peopleLoading = false;
    } else {
      _loadPeople();
    }
  }

  void _loadPeople() => context.read<InspectionBloc>().add(
    BusinessPeopleRequested(widget.vendor!.id),
  );

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _changed(String value) {
    context.read<InspectionBloc>().invalidatePersonSearch();
    setState(() {
      _checked = false;
      _hasMore = false;
      _loading = false;
      _candidates.clear();
      _confirmed = null;
      _message = null;
    });
    widget.onChanged(null, _name.text.trim());
  }

  // One tap fills the paper name from the record, so nothing is retyped.
  void _select(PersonCandidate person) {
    setState(() {
      _confirmed = person;
      _name.text = person.fullName;
    });
    widget.onChanged(person, person.fullName);
  }

  void _findOwner() {
    _name.text = widget.vendor!.ownerName;
    _changed(_name.text);
    _check();
  }

  void _check({int offset = 0}) {
    if (_name.text.trim().isEmpty || _loading) return;
    FocusScope.of(context).unfocus();
    context.read<InspectionBloc>().add(
      PersonMatchesRequested(
        _name.text.trim(),
        _address.text.trim(),
        _phone.text.trim(),
        offset: offset,
      ),
    );
  }

  Future<void> _create() async {
    if (!_checked || _loading) return;
    final person = await showModalBottomSheet<PersonCandidate>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: context.read<InspectionBloc>(),
        child: CreatePersonSheet(
          name: _name.text.trim(),
          address: _address.text.trim(),
          phone: _phone.text.trim(),
        ),
      ),
    );
    if (!mounted) return;
    // A failed/uncertain request must be checked against actual records before retry.
    setState(() {
      _checked = false;
      _confirmed = null;
    });
    widget.onChanged(null, _name.text.trim());
    if (person != null) {
      setState(() {
        _candidates.insert(0, person);
        _checked = true;
        _message = 'Person created. Confirm this is the violator.';
      });
    } else {
      _check();
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<InspectionBloc, InspectionState>(
    listener: (context, state) {
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
      if (state is PersonMatchesLoading) {
        setState(() {
          _loading = true;
          _message = null;
        });
      }
      if (state is PersonMatchesLoaded && state.name == _name.text.trim()) {
        setState(() {
          _loading = false;
          _checked = true;
          _hasMore = state.page.hasMore;
          if (state.offset == 0) _candidates.clear();
          _candidates.addAll(state.page.items);
          _message = _candidates.isEmpty
              ? 'No possible matches. Review the name and details before creating a person.'
              : 'Compare the details. A name match does not confirm identity.';
        });
      }
      if (state is PersonMatchesError) {
        setState(() {
          _loading = false;
          _checked = false;
          _message = state.message;
        });
      }
    },
    builder: (context, state) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.vendor != null)
          BusinessPeopleSection(
            ownerName: widget.vendor!.ownerName,
            people: _people,
            loading: _peopleLoading,
            error: _peopleError,
            selectedId: _confirmed?.id,
            onFindOwner: _findOwner,
            onRetry: _loadPeople,
            onSelect: _select,
          ),
        Text(
          'Add helper or another person',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Text(
          'Enter the name from the paper, then search all person records.',
        ),
        TextField(
          controller: _name,
          maxLength: 200,
          onChanged: _changed,
          decoration: const InputDecoration(
            labelText: 'Paper violator name',
            helperText: 'Keep the spelling written on the paper.',
          ),
        ),
        TextField(
          controller: _address,
          maxLength: 500,
          onChanged: _changed,
          decoration: const InputDecoration(
            labelText: 'Reviewed address (optional for matching)',
          ),
        ),
        TextField(
          controller: _phone,
          maxLength: 11,
          keyboardType: TextInputType.phone,
          onChanged: _changed,
          decoration: const InputDecoration(labelText: 'Phone (optional)'),
        ),
        OutlinedButton(
          onPressed: _loading ? null : () => _check(),
          child: Text(
            _loading ? 'Checking records…' : 'Check possible matches',
          ),
        ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppTheme.ticketSmallGap,
            ),
            child: Text(_message!),
          ),
        for (final person in _candidates)
          PersonRecordTile(
            key: ValueKey('person-match-${person.id}'),
            person: person,
            details: [
              person.address,
              person.phoneNumber ?? 'No phone recorded',
              if (person.matchedFields.isNotEmpty)
                'Matches: ${person.matchedFields.join(', ')}',
              if (person.ticketTotals.businessNames.isNotEmpty)
                'Ticketed at: ${person.ticketTotals.businessNames.join(', ')}',
            ],
            actionLabel: _confirmed?.id == person.id
                ? 'Selected'
                : 'Same person – select',
            onAction: _loading || !_checked ? null : () => _select(person),
          ),
        if (_hasMore)
          TextButton(
            onPressed: _loading
                ? null
                : () => _check(offset: _candidates.length),
            child: const Text('More possible matches'),
          ),
        if (_checked)
          TextButton(
            onPressed: _loading ? null : _create,
            child: Text(
              _candidates.isEmpty
                  ? 'New person'
                  : 'Not any of these – new person',
            ),
          ),
        if (_confirmed != null) ...[
          Text(
            'Confirmed person: ${_confirmed!.fullName} (Person ${_confirmed!.id})',
          ),
          TextButton(
            onPressed: () => PersonHistorySheet.show(
              context,
              _confirmed!.id,
              _confirmed!.fullName,
            ),
            child: const Text('View person citation history'),
          ),
        ],
        const SizedBox(height: AppTheme.ticketSmallGap),
      ],
    ),
  );
}
