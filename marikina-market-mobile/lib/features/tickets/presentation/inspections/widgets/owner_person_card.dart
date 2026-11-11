import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_primary_btn.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/person_candidate.dart';
import 'form/bottom_sheets/selection_chip.dart';
import 'person_result_card.dart';

// The business owner, shown first. A found owner is chosen with one tap; an
// owner without a person record is added with one tap, nothing typed.
class OwnerPersonCard extends StatelessWidget {
  // From the business record, shown until the owner has a person record.
  final String ownerName;
  final PersonCandidate? owner;
  final bool isLoading;
  final String? error;
  final bool isAdding;
  final String? addError;
  final VoidCallback onRetry;
  final VoidCallback onAdd;
  final ValueChanged<PersonCandidate> onSelect;

  const OwnerPersonCard({
    required this.ownerName,
    required this.owner,
    required this.isLoading,
    required this.error,
    required this.isAdding,
    required this.addError,
    required this.onRetry,
    required this.onAdd,
    required this.onSelect,
    super.key,
  });

  Widget _box(ColorScheme colors, List<Widget> children) => Padding(
    padding: AppTheme.selectionSheetItemPadding,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppTheme.controlRadius,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: AppTheme.selectionCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final person = owner;
    if (isLoading) {
      return _box(colors, [
        Row(
          children: [
            SizedBox.square(
              dimension: AppTheme.buttonIconSize,
              child: CircularProgressIndicator(
                value: MediaQuery.disableAnimationsOf(context) ? 0.75 : null,
                strokeWidth: AppTheme.buttonProgressStrokeWidth,
                semanticsLabel: 'Loading owner',
              ),
            ),
            const SizedBox(width: AppTheme.inspectionSmallGap),
            const Text('Loading owner…', style: AppTheme.inspectionBodyStyle),
          ],
        ),
      ]);
    }
    if (error != null) {
      return _box(colors, [
        Text(
          error!,
          style: AppTheme.inspectionBodyStyle.copyWith(color: colors.error),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ),
      ]);
    }
    if (person != null) {
      return PersonResultCard(
        person: person,
        isOwner: true,
        onTap: () => onSelect(person),
      );
    }
    return _box(colors, [
      Text(ownerName, style: AppTheme.cardHeadingStyle),
      const SizedBox(height: AppTheme.inspectionSmallGap),
      const Align(
        alignment: Alignment.centerLeft,
        child: SelectionChip(text: 'Owner', isAccent: true),
      ),
      const SizedBox(height: AppTheme.inspectionSmallGap),
      if (addError != null) ...[
        Text(
          addError!,
          style: AppTheme.inspectionBodyStyle.copyWith(color: colors.error),
        ),
        const SizedBox(height: AppTheme.inspectionSmallGap),
      ],
      AppPrimaryButton(
        label: 'Add owner as person',
        iconData: Icons.person_add_alt,
        isLoading: isAdding,
        onPressed: onAdd,
      ),
    ]);
  }
}
