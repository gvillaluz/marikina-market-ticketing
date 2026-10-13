import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/utils/date_formatter_util.dart';
import '../../domain/entities/vendor_ticket_detail.dart';
import '../../domain/enums/records_filter.dart';
import 'record_detail_row.dart';
import 'record_evidence_grid.dart';

class VendorRecordDetailContent extends StatelessWidget {
  final VendorTicketDetail detail;
  const VendorRecordDetailContent({required this.detail, super.key});
  @override
  Widget build(BuildContext context) {
    final warning = detail.type == RecordsFilter.warning;
    final penalty = PenaltyType.values
        .where((type) => type.value == detail.penaltyType)
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          warning ? 'Written Warning Record' : 'Ticket Record',
          style: AppTheme.profileHeadingStyle.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppTheme.inspectionSmallGap),
        Card(
          child: Padding(
            padding: AppTheme.ticketCardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'City of Marikina',
                  textAlign: TextAlign.center,
                  style: AppTheme.inspectionHeadingStyle,
                ),
                const Text(
                  'Marikina Public Market Office',
                  textAlign: TextAlign.center,
                ),
                const Divider(),
                if (detail.controlNumber != null)
                  RecordDetailRow(
                    label: 'Control number',
                    value: detail.controlNumber!,
                  ),
                RecordDetailRow(
                  label: 'Issued',
                  value: DateTimeFormatter.getShortDateTime(detail.issuedAt),
                ),
                RecordDetailRow(label: 'Business', value: detail.businessName),
                RecordDetailRow(label: 'Vendor type', value: detail.vendorType),
                RecordDetailRow(
                  label: 'Vendor',
                  value: '${detail.lastName}, ${detail.firstName}',
                ),
                RecordDetailRow(label: 'Business ID', value: detail.businessId),
                if (detail.stallNumber != null)
                  RecordDetailRow(
                    label: 'Stall number',
                    value: detail.stallNumber!,
                  ),
                RecordDetailRow(
                  label: 'Market section',
                  value: detail.marketSection,
                ),
                if (detail.address?.trim().isNotEmpty == true)
                  RecordDetailRow(label: 'Address', value: detail.address!),
                const Divider(),
                Text(
                  'Violation details',
                  style: AppTheme.inspectionHeadingStyle,
                ),
                for (final violation in detail.violations) ...[
                  RecordDetailRow(
                    label: 'Ordinance ${violation.ordinanceNumber}',
                    value: violation.ordinanceCode,
                  ),
                  RecordDetailRow(
                    label: 'Offense count',
                    value: '${violation.offenseCount}',
                  ),
                  if (!warning && violation.penaltyAmount != null)
                    RecordDetailRow(
                      label: 'Penalty',
                      value: '₱${violation.penaltyAmount!.toStringAsFixed(2)}',
                    ),
                ],
                if (detail.categories.isNotEmpty)
                  RecordDetailRow(
                    label: 'Categories',
                    value: detail.categories.join(', '),
                  ),
                RecordDetailRow(
                  label: 'Description',
                  value: detail.description,
                ),
                if (detail.severity != null)
                  RecordDetailRow(label: 'Severity', value: detail.severity!),
                if (!warning) ...[
                  const Divider(),
                  Text(
                    'Penalty details',
                    style: AppTheme.inspectionHeadingStyle,
                  ),
                  if (detail.penaltyType != null)
                    RecordDetailRow(
                      label: 'Penalty type',
                      value: penalty?.label ?? detail.penaltyType!,
                    ),
                  if (detail.status != null)
                    RecordDetailRow(
                      label: 'Status',
                      value: detail.status!.value,
                    ),
                  if (detail.dueDate != null)
                    RecordDetailRow(
                      label: 'Due date',
                      value: DateTimeFormatter.getShortDate(detail.dueDate!),
                    ),
                  if (detail.totalFine != null)
                    RecordDetailRow(
                      label: 'Total fine',
                      value: '₱${detail.totalFine!.toStringAsFixed(2)}',
                    ),
                  if (detail.communityServiceHours != null)
                    RecordDetailRow(
                      label: 'Community service hours',
                      value: '${detail.communityServiceHours}',
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.inspectionGap),
        Text('Photo evidence', style: AppTheme.inspectionHeadingStyle),
        const SizedBox(height: AppTheme.inspectionSmallGap),
        if (detail.evidenceUrls.isEmpty)
          const Text('No photo evidence found.')
        else
          RecordEvidenceGrid(urls: detail.evidenceUrls),
      ],
    );
  }
}
