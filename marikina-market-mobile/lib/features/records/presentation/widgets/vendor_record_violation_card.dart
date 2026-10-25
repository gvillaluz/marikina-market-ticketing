import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/utils/extentions/integer_extensions.dart';
import '../../domain/entities/record_violation.dart';

class VendorRecordViolationCard extends StatelessWidget {
  final RecordViolation violation;
  final bool warning;
  const VendorRecordViolationCard({
    required this.violation,
    required this.warning,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final count = violation.offenseCount;
    final background = AppTheme.ticketOffenseBackground(count);
    final foreground = AppTheme.ticketOffenseColor(count);
    return Container(
      padding: AppTheme.ticketOrdinancePadding,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lightGrey),
        borderRadius: AppTheme.ticketOrdinanceRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ord No. ${violation.ordinanceNumber}',
            style: const TextStyle(fontSize: AppTheme.bodyFontSize),
          ),
          const SizedBox(height: AppTheme.ticketTinyGap),
          Text(
            violation.ordinanceCode,
            style: const TextStyle(
              fontSize: AppTheme.captionFontSize,
              height: 1,
              color: AppColors.mediumGrey,
            ),
          ),
          if (!warning) ...[
            const SizedBox(height: AppTheme.ticketSmallGap),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: AppTheme.ticketTinyGap,
              children: [
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: AppTheme.ticketOffensePadding,
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: AppTheme.ticketOrdinanceRadius,
                      ),
                      child: Wrap(
                        spacing: AppTheme.ticketTinyGap,
                        children: [
                          Icon(
                            Icons.restore_outlined,
                            color: foreground,
                            size: 15,
                          ),
                          Text(
                            '${count.toOrdinal()} offense',
                            style: TextStyle(
                              color: foreground,
                              fontSize: AppTheme.captionFontSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Preserve vendor amounts for every existing penalty type.
                if (violation.penaltyAmount != null)
                  Flexible(
                    flex: 2,
                    child: Text(
                      '₱${violation.penaltyAmount!.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
