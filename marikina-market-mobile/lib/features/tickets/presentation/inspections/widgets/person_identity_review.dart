import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/person_candidate.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import 'create_person_sheet.dart';
import 'person_history_sheet.dart';

class PersonIdentityReview extends StatefulWidget {
  final void Function(PersonCandidate? person, String paperName) onChanged;
  const PersonIdentityReview({super.key, required this.onChanged});
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
        Text(
          'Violator identity',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Text(
          'Enter the reviewed paper details, then check possible person records.',
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
          ListTile(
            contentPadding: EdgeInsets.zero,
            isThreeLine: true,
            title: Text('${person.fullName} · Person ${person.id}'),
            subtitle: Text(
              '${person.address}\n${person.phoneNumber ?? 'No phone recorded'}${person.matchedFields.isEmpty ? '' : '\nMatches: ${person.matchedFields.join(', ')}'}',
            ),
            trailing: TextButton(
              onPressed: _loading || !_checked
                  ? null
                  : () {
                      setState(() => _confirmed = person);
                      widget.onChanged(person, _name.text.trim());
                    },
              child: Text(
                _confirmed?.id == person.id ? 'Confirmed' : 'Confirm',
              ),
            ),
            onTap: () =>
                PersonHistorySheet.show(context, person.id, person.fullName),
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
            child: const Text('None of these people — create a new person'),
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
