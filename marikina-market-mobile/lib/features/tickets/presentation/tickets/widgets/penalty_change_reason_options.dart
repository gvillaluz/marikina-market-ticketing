import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/penalty_change_reason.dart';

class PenaltyChangeReasonOptions extends StatelessWidget {
  final PenaltyChangeReason? selected;
  final ValueChanged<PenaltyChangeReason> onChanged;

  const PenaltyChangeReasonOptions({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Reason for the change',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppTheme.ticketTinyGap),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(borderRadius: AppTheme.controlRadius),
          foregroundDecoration: BoxDecoration(
            borderRadius: AppTheme.controlRadius,
            border: Border.all(color: AppColors.lightGrey, width: 0.8),
          ),
          child: Column(
            children: [
              for (final reason in PenaltyChangeReason.values) ...[
                if (reason != PenaltyChangeReason.values.first)
                  const Divider(height: 1, color: AppColors.lightGrey),
                _buildReasonRow(reason),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReasonRow(PenaltyChangeReason reason) {
    final isSelected = reason == selected;

    return MergeSemantics(
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        checked: isSelected,
        child: InkWell(
          onTap: () => onChanged(reason),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: kMinInteractiveDimension,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: AppTheme.ticketIconSize,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.mediumGrey,
                  ),
                  const SizedBox(width: AppTheme.reasonRadioGap),
                  Expanded(
                    child: Text(
                      reason.label,
                      style: TextStyle(
                        fontSize: AppTheme.bodyFontSize,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: AppColors.primaryBlack,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
