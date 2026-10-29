import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';

class CreatePersonSheet extends StatefulWidget {
  final String name, address, phone;
  const CreatePersonSheet({
    super.key,
    required this.name,
    required this.address,
    required this.phone,
  });
  @override
  State<CreatePersonSheet> createState() => _CreatePersonSheetState();
}

class _CreatePersonSheetState extends State<CreatePersonSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.name);
  late final _address = TextEditingController(text: widget.address);
  late final _phone = TextEditingController(text: widget.phone);
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
      if (state is PersonCreationError) {
        setState(() {
          _busy = false;
          _uncertain = true;
          _error =
              '${state.message} Close this sheet and check possible matches before retrying.';
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
                  'Create person',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Text(
                  'Create only after reviewing possible matches. Existing registry details can be changed by an admin.',
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
