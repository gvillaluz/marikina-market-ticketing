import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/community_service_log.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'vendor_settlement_photo.dart';
import 'record_detail_row.dart';

class VendorServiceLogEntry extends StatelessWidget {
  final CommunityServiceLog entry;
  final int index;
  const VendorServiceLogEntry({
    required this.entry,
    required this.index,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: AppTheme.selectionSheetItemPadding,
    child: Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: AppTheme.controlRadius,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Semantics(
          label: 'Service entry ${index + 1}',
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppTheme.profileSmallGap,
            children: [
              Text(
                DateFormat('MMM d, yyyy').format(entry.serviceDate),
                style: AppTheme.recordsCardTitleStyle,
              ),
              Container(
                padding: AppTheme.recordsStatusPadding,
                decoration: BoxDecoration(
                  color: AppTheme.recordsFilterBackground,
                  borderRadius: AppTheme.controlRadius,
                ),
                child: Text(
                  '${entry.hoursWorked.toStringAsFixed(entry.hoursWorked == entry.hoursWorked.roundToDouble() ? 0 : 2)}h',
                  style: AppTheme.recordsCardTitleStyle,
                ),
              ),
            ],
          ),
        ),
        childrenPadding: AppTheme.settlementCardPadding,
        children: [
          RecordDetailRow(
            label: 'Date',
            value: DateFormat('MM/dd/yyyy').format(entry.serviceDate),
          ),
          RecordDetailRow(
            label: 'Hours worked',
            value:
                '${entry.hoursWorked.toStringAsFixed(entry.hoursWorked == entry.hoursWorked.roundToDouble() ? 0 : 2)} hours',
          ),
          VendorSettlementPhoto(
            url: entry.proofUrl,
            title: 'Community service proof',
            height: AppTheme.settlementServiceProofHeight,
          ),
        ],
      ),
    ),
  );
}
