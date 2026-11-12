import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

// What is written on the paper: the control number (tickets only) and the
// place. A warning and a ticket share the same place field.
class PaperCitationFields extends StatelessWidget {
  final bool isTicket;
  final TextEditingController referenceController;
  final TextEditingController placeController;

  const PaperCitationFields({
    required this.isTicket,
    required this.referenceController,
    required this.placeController,
    super.key,
  });

  String? _validatePlace(String? value) {
    if (value == null || value.trim().isEmpty) {
      return isTicket
          ? 'Issue place is required.'
          : 'Enter where the warning was issued.';
    }
    return isTicket && value.trim().length > 500
        ? 'Use at most 500 characters.'
        : null;
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (isTicket) ...[
        const Text('Control number', style: AppTheme.ticketPaperLabelStyle),
        const SizedBox(height: AppTheme.inspectionTinyGap),
        Semantics(
          label: 'Control number',
          child: TextFormField(
            key: const ValueKey('paper-reference'),
            controller: referenceController,
            maxLength: 200,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'Number printed on the paper ticket',
              counterText: '',
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Control number is required.'
                : value.trim().length > 200
                ? 'Use at most 200 characters.'
                : null,
          ),
        ),
        const SizedBox(height: AppTheme.inspectionSmallGap),
      ],
      const Text('Issue place', style: AppTheme.ticketPaperLabelStyle),
      const SizedBox(height: AppTheme.inspectionTinyGap),
      Semantics(
        label: 'Issue place',
        child: TextFormField(
          key: ValueKey(isTicket ? 'issue-place' : 'warning-issue-place'),
          controller: placeController,
          maxLength: 500,
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Place written on the paper',
            counterText: '',
          ),
          validator: _validatePlace,
        ),
      ),
    ],
  );
}
