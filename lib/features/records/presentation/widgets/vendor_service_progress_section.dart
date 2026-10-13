import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/community_service_progress.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'vendor_service_log_entry.dart';

class VendorServiceProgressSection extends StatelessWidget {
  final CommunityServiceProgress progress;
  const VendorServiceProgressSection({required this.progress, super.key});
  String _hours(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Container(
            padding: AppTheme.settlementClockPadding,
            decoration: const BoxDecoration(
              color: AppTheme.settlementClockBackground,
              borderRadius: AppTheme.controlRadius,
            ),
            child: const Icon(
              Icons.access_time,
              color: AppTheme.settlementClockColor,
              size: AppTheme.buttonIconSize,
            ),
          ),
          const SizedBox(width: AppTheme.profileSmallGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community Service Log',
                  style: AppTheme.inspectionBodyStyle.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${_hours(progress.hoursCompleted)} of ${progress.hoursRequired} hrs completed',
                  style: AppTheme.inspectionBodyStyle,
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: AppTheme.profileSmallGap),
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: AppTheme.profileSmallGap,
        children: [
          Text(
            '${_hours(progress.hoursCompleted)} logged',
            style: AppTheme.recordsCaptionStyle,
          ),
          Text(
            '${progress.completionPercentage.round()}% of ${progress.hoursRequired} hrs',
            style: AppTheme.recordsCaptionStyle,
          ),
        ],
      ),
      const SizedBox(height: AppTheme.inspectionTinyGap),
      ClipRRect(
        borderRadius: AppTheme.controlRadius,
        child: LinearProgressIndicator(
          value: (progress.completionPercentage / 100).clamp(0.0, 1.0),
          minHeight: AppTheme.settlementProgressHeight,
        ),
      ),
      const SizedBox(height: AppTheme.inspectionTinyGap),
      Text(
        '${_hours(progress.hoursRemaining)} hrs remaining',
        textAlign: TextAlign.right,
        style: AppTheme.recordsCaptionStyle,
      ),
      const SizedBox(height: AppTheme.profileSmallGap),
      if (progress.entries.isEmpty)
        const Text('No community service entries yet.')
      else
        for (var index = 0; index < progress.entries.length; index++)
          VendorServiceLogEntry(
            key: ValueKey(index),
            entry: progress.entries[index],
            index: index,
          ),
      Text(
        'Community service entries are read-only.',
        style: AppTheme.inspectionBodyStyle,
      ),
    ],
  );
}
