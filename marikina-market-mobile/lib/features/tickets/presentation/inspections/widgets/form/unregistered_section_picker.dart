import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/market_section.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';

// The office's list of market sections. The enforcer taps the one where the
// unregistered vendor was found.
class UnregisteredSectionPicker extends StatefulWidget {
  final ValueChanged<MarketSection> onSelected;

  const UnregisteredSectionPicker({required this.onSelected, super.key});

  @override
  State<UnregisteredSectionPicker> createState() =>
      _UnregisteredSectionPickerState();
}

class _UnregisteredSectionPickerState extends State<UnregisteredSectionPicker> {
  bool _loading = true;
  String? _error;
  List<MarketSection> _sections = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => context.read<InspectionBloc>().add(MarketSectionsRequested());

  Widget _content() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Column(
        spacing: AppTheme.inspectionTinyGap,
        children: [
          Text(_error!, textAlign: TextAlign.center),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ],
      );
    }
    if (_sections.isEmpty) {
      return const Text(
        'No active market sections. Ask the office to add one.',
        textAlign: TextAlign.center,
      );
    }
    return Wrap(
      spacing: AppTheme.inspectionTinyGap,
      runSpacing: AppTheme.inspectionTinyGap,
      children: [
        for (final section in _sections)
          ActionChip(
            label: Text(section.name),
            onPressed: () => widget.onSelected(section),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<InspectionBloc, InspectionState>(
        listener: (context, state) {
          if (state is MarketSectionsLoading) {
            setState(() {
              _loading = true;
              _error = null;
            });
          }
          if (state is MarketSectionsLoaded) {
            setState(() {
              _loading = false;
              _sections = state.sections;
            });
          }
          if (state is MarketSectionsError) {
            setState(() {
              _loading = false;
              _error = state.message;
            });
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppTheme.inspectionSmallGap,
          children: [
            const Text(
              'Market section',
              style: AppTheme.inspectionHeadingStyle,
            ),
            _content(),
          ],
        ),
      );
}
