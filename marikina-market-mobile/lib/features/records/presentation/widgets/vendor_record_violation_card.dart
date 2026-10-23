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
    // Same offense palette as the issued enforcer paper.
    final background = count > 2
        ? const Color(0xFFFCEBEB)
        : count > 1
        ? const Color(0xFFFAEEDA)
        : const Color(0xFFEAF3DE);
    final foreground = count > 2
        ? const Color(0xFF791F1F)
        : count > 1
        ? const Color(0xFF633806)
        : const Color(0xFF27500A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lightGrey),
        borderRadius: BorderRadius.circular(10),
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
          const SizedBox(height: AppTheme.ticketSmallGap),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Wrap(
                spacing: AppTheme.ticketTinyGap,
                children: [
                  Icon(Icons.restore_outlined, color: foreground, size: 15),
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
          // Preserve the vendor's existing amount visibility for every penalty type.
          if (!warning && violation.penaltyAmount != null) ...[
            const SizedBox(height: AppTheme.ticketTinyGap),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '₱${violation.penaltyAmount!.toStringAsFixed(2)}',
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
