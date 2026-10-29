import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class PaperCitationFields extends StatelessWidget {
  final TextEditingController referenceController;
  final TextEditingController placeController;

  const PaperCitationFields({
    required this.referenceController,
    required this.placeController,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('Paper reference', style: AppTheme.ticketPaperLabelStyle),
      const SizedBox(height: AppTheme.inspectionTinyGap),
      Semantics(
        label: 'Paper reference',
        child: TextFormField(
          key: const ValueKey('paper-reference'),
          controller: referenceController,
          maxLength: 200,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'Reference printed on the ticket',
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Paper reference is required.'
              : value.trim().length > 200
              ? 'Use at most 200 characters.'
              : null,
        ),
      ),
      const SizedBox(height: AppTheme.ticketSmallGap),
      const Text('Issue place', style: AppTheme.ticketPaperLabelStyle),
      const SizedBox(height: AppTheme.inspectionTinyGap),
      Semantics(
        label: 'Issue place',
        child: TextFormField(
          key: const ValueKey('issue-place'),
          controller: placeController,
          maxLength: 500,
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Place written on the ticket',
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Issue place is required.'
              : value.trim().length > 500
              ? 'Use at most 500 characters.'
              : null,
        ),
      ),
      const SizedBox(height: AppTheme.ticketSmallGap),
    ],
  );
}
