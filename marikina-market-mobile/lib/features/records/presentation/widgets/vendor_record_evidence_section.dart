import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'record_evidence_grid.dart';

class VendorRecordEvidenceSection extends StatelessWidget {
  final List<String> urls;
  const VendorRecordEvidenceSection({required this.urls, super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Photo Evidence Record',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: AppTheme.sectionHeadingFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      const Text('Photos attached to this inspection record.'),
      const SizedBox(height: 10),
      Container(
        padding: urls.isEmpty
            ? const EdgeInsets.symmetric(vertical: 32, horizontal: 24)
            : AppTheme.ticketCardPadding,
        decoration: BoxDecoration(
          color: urls.isEmpty
              ? AppColors.primaryLight
              : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: urls.isEmpty
                ? AppColors.lightGrey.withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: AppTheme.ticketCardRadius,
        ),
        child: urls.isNotEmpty
            ? RecordEvidenceGrid(urls: urls)
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: .10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.assignment_turned_in_outlined,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No photo evidence',
                    style: TextStyle(
                      fontSize: AppTheme.sectionHeadingFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'No photos are attached to this record.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppTheme.captionFontSize,
                      color: AppColors.mediumGrey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
      ),
    ],
  );
}
