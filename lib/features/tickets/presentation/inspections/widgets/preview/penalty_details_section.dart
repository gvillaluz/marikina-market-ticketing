import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/core/utils/date_formatter_util.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/detail_row.dart';

class PenaltyDetailsSection extends StatelessWidget {
  final Severity severity;
  final PenaltyType penaltyType;
  final double totalFineAmount;
  final int? communityHrs;

  const PenaltyDetailsSection({
    required this.severity,
    required this.penaltyType,
    required this.totalFineAmount,
    required this.communityHrs,
    super.key,
  });

  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
  );

  Color _getBgColor() {
    if (severity == Severity.high) {
      return AppColors.secondaryRed;
    } else if (severity == Severity.moderate) {
      return AppColors.primaryYellow;
    } else {
      return AppColors.tertiary;
    }
  }

  Color _getColor() {
    if (severity == Severity.high) {
      return AppColors.primaryRed;
    } else if (severity == Severity.moderate) {
      return AppColors.secondaryYellow;
    } else {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final penalty = penaltyType == PenaltyType.communityService
        ? '${penaltyType.value} ($communityHrs hrs)'
        : penaltyType.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppTheme.inspectionSmallGap,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Text(
                '₱',
                style: TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: AppTheme.sectionHeadingFontSize,
                ),
              ),
            ),
            const Text(
              'PENALTY DETAILS',
              style: TextStyle(
                fontSize: AppTheme.sectionHeadingFontSize,
                color: AppColors.primary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        Column(
          spacing: AppTheme.inspectionSmallGap,
          children: [
            DetailRow(
              label: 'SEVERITY:',
              value: severity.value,
              valueWidget: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: _getBgColor(),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: Text(
                    severity.value,
                    style: TextStyle(color: _getColor()),
                  ),
                ),
              ),
            ),
            DetailRow(label: 'PENALTY TYPE:', value: penalty),
            DetailRow(
              label: 'DUE DATE:',
              value:
                  '${DateTimeFormatter.getDate(DateTime.now().add(const Duration(days: 5)))}\n (5 days from issuance)',
            ),
          ],
        ),

        if (penaltyType == PenaltyType.cashFine) ...[
          const SizedBox(height: AppTheme.inspectionSmallGap),

          Container(
            width: double.infinity,
            padding: AppTheme.inspectionCardPadding,
            decoration: BoxDecoration(
              color: AppColors.tertiary,
              borderRadius: AppTheme.inspectionCardRadius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Fine Due:',
                  style: AppTheme.inspectionHeadingStyle,
                ),
                const SizedBox(height: AppTheme.inspectionTinyGap),
                Text(
                  _currencyFormat.format(totalFineAmount),
                  style: AppTheme.detailTitleStyle.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.inspectionSmallGap),

          const Text(
            'Please settle the fine on or before the due date to avoid additional penalties',
            style: AppTheme.inspectionCaptionStyle,
          ),
        ],
      ],
    );
  }
}
