import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';

class CreatePersonSheet extends StatefulWidget {
  // The name typed in the search, so it is not typed twice.
  final String name;
  const CreatePersonSheet({super.key, required this.name});
  @override
  State<CreatePersonSheet> createState() => _CreatePersonSheetState();
}

class _CreatePersonSheetState extends State<CreatePersonSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.name);
  final _address = TextEditingController();
  final _phone = TextEditingController();
  bool _busy = false, _uncertain = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<InspectionBloc, InspectionState>(
    listener: (context, state) {
      if (state is PersonCreationLoading) setState(() => _busy = true);
      if (state is PersonCreated) Navigator.pop(context, state.person);
      // Create stays locked after any failure: search again before retrying.
      if (state is PersonCreationError) {
        setState(() {
          _busy = false;
          _uncertain = true;
          _error =
              '${state.message ?? 'Could not confirm it was saved.'} '
              'Close and search again before retrying.';
        });
      }
    },
    builder: (context, state) => PopScope(
      canPop: !_busy,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: AppTheme.ticketDetailPadding,
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'New person',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextFormField(
                  controller: _name,
                  enabled: !_busy,
                  maxLength: 200,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Name is required.'
                      : null,
                ),
                TextFormField(
                  controller: _address,
                  enabled: !_busy,
                  maxLength: 500,
                  decoration: const InputDecoration(labelText: 'Address'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Address is required.'
                      : null,
                ),
                TextFormField(
                  controller: _phone,
                  enabled: !_busy,
                  maxLength: 11,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                  ),
                  validator: (v) =>
                      v != null &&
                          v.isNotEmpty &&
                          !RegExp(r'^09[0-9]{9}$').hasMatch(v)
                      ? 'Use 11 digits starting with 09.'
                      : null,
                ),
                if (_error != null) Text(_error!),
                ElevatedButton(
                  onPressed: _busy || _uncertain
                      ? null
                      : () {
                          if (!_form.currentState!.validate()) return;
                          context.read<InspectionBloc>().add(
                            PersonCreationRequested(
                              _name.text.trim(),
                              _address.text.trim(),
                              _phone.text.isEmpty ? null : _phone.text,
                            ),
                          );
                        },
                  child: Text(_busy ? 'Creating…' : 'Create person'),
                ),
                TextButton(
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
