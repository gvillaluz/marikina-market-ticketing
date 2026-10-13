import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/utils/date_formatter_util.dart';
import '../../domain/entities/vendor_record.dart';
import '../../domain/enums/records_filter.dart';

class RecordCard extends StatelessWidget {
  final VendorRecord record;
  const RecordCard({required this.record, super.key});
  void _open(BuildContext context) => context.pushNamed(
    Routes.vendorRecordDetailName,
    pathParameters: {'ticketId': record.ticketId.toString()},
  );
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final warning = record.type == RecordsFilter.warning;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.controlRadius,
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context),
        child: Padding(
          padding: AppTheme.recordsCardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: AppTheme.inspectionTinyGap,
                      children: [
                        Text(
                          warning ? 'Written Warning' : 'Ticket',
                          style: AppTheme.recordsCardTitleStyle.copyWith(
                            color: colors.primary,
                          ),
                        ),
                        if (!warning &&
                            record.controlNumber?.trim().isNotEmpty == true)
                          Text(
                            '#${record.controlNumber}',
                            style: AppTheme.recordsCardTitleStyle.copyWith(
                              color: colors.error,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!warning && record.status != null)
                    Container(
                      padding: AppTheme.recordsStatusPadding,
                      decoration: BoxDecoration(
                        color: AppTheme.ticketStatusBackground(
                          record.status!.value,
                        ),
                        borderRadius: AppTheme.controlRadius,
                      ),
                      child: Text(
                        record.status!.value,
                        style: AppTheme.recordsCaptionStyle.copyWith(
                          color: AppTheme.ticketStatusColor(
                            record.status!.value,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.inspectionTinyGap),
              Text(
                record.violations.isEmpty
                    ? 'No violation details provided.'
                    : record.violations.join(' • '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.recordsBodyStyle.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.inspectionSmallGap),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppTheme.inspectionTinyGap,
                children: [
                  Text(
                    'Issued ${DateTimeFormatter.getShortDateTime(record.issuedAt)}',
                    style: AppTheme.recordsCaptionStyle.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      textStyle: AppTheme.recordsCaptionStyle,
                    ),
                    onPressed: () => _open(context),
                    child: const Text('View Details ›'),
                  ),
                ],
              ),
              if (!warning && record.overdueDate != null)
                Text(
                  'Due: ${DateTimeFormatter.getShortDate(record.overdueDate!)}',
                  style: AppTheme.recordsCaptionStyle.copyWith(
                    color: colors.error,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
