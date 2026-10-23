import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/utils/date_formatter_util.dart';
import '../../domain/entities/vendor_ticket_detail.dart';
import '../../domain/enums/records_filter.dart';
import 'vendor_record_violation_card.dart';
import 'vendor_ticket_paper_field.dart';
import 'vendor_ticket_paper_header.dart';
import 'vendor_ticket_paper_section_title.dart';
import 'vendor_record_evidence_section.dart';

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
          style: AppTheme.detailTitleStyle.copyWith(color: AppColors.primary),
        ),
        Text(
          warning
              ? 'Review the issued written warning and inspection details.'
              : 'Review the issued record, evidence and settlement details.',
          style: AppTheme.pageSubtitleStyle.copyWith(
            color: AppColors.mediumGrey,
          ),
        ),
        if (!warning && detail.status != null) ...[
          const SizedBox(height: AppTheme.ticketSmallGap),
          Align(
            alignment: Alignment.centerLeft,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.ticketStatusBackground(detail.status!.value),
                borderRadius: AppTheme.controlRadius,
              ),
              child: Padding(
                padding: AppTheme.ticketBadgePadding,
                child: Text(
                  detail.status!.label,
                  style: AppTheme.ticketCaptionStyle.copyWith(
                    color: AppTheme.ticketStatusColor(detail.status!.value),
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: AppTheme.ticketSmallGap),
        Container(
          decoration: AppTheme.ticketPaperDecoration,
          padding: EdgeInsets.symmetric(
            vertical: AppTheme.ticketCardPadding.top,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.ticketCardPadding.left,
                ),
                child: VendorTicketPaperHeader(
                  isTicket: !warning,
                  controlNumber: detail.controlNumber,
                ),
              ),
              const SizedBox(height: AppTheme.ticketSmallGap),
              const Divider(height: AppTheme.ticketSmallGap),
              const SizedBox(height: AppTheme.ticketSmallGap),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.ticketCardPadding.left,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppTheme.ticketSmallGap,
                  children: [
                    const VendorTicketPaperSectionTitle(
                      icon: Icons.person_outline,
                      title: 'VIOLATOR DETAILS',
                    ),
                    VendorTicketPaperField(
                      label: 'BUSINESS ID:',
                      value: detail.businessId,
                    ),
                    if (detail.stallNumber != null)
                      VendorTicketPaperField(
                        label: 'STALL/UNIT NO:',
                        value: detail.stallNumber!,
                      ),
                    VendorTicketPaperField(
                      label: 'TRADE NAME:',
                      value: detail.businessName,
                    ),
                    VendorTicketPaperField(
                      label: 'NAME:',
                      value: '${detail.lastName}, ${detail.firstName}',
                    ),
                    VendorTicketPaperField(
                      label: 'VENDOR TYPE:',
                      value: detail.vendorType,
                    ),
                    if (detail.address?.trim().isNotEmpty == true)
                      VendorTicketPaperField(
                        label: 'ADDRESS:',
                        value: detail.address!,
                      ),
                    const Divider(),
                    const VendorTicketPaperSectionTitle(
                      icon: Icons.receipt_long_outlined,
                      title: 'VIOLATION DETAILS',
                    ),
                    const Text(
                      'ORDINANCE:',
                      style: AppTheme.ticketPaperLabelStyle,
                    ),
                    for (final violation in detail.violations)
                      VendorRecordViolationCard(
                        violation: violation,
                        warning: warning,
                      ),
                    VendorTicketPaperField(
                      label: 'DATE & TIME:',
                      value: DateTimeFormatter.getShortDateTime(
                        detail.issuedAt,
                      ),
                    ),
                    VendorTicketPaperField(
                      label: 'LOCATION:',
                      value: detail.marketSection,
                    ),
                    if (detail.categories.isNotEmpty)
                      VendorTicketPaperField(
                        label: 'VIOLATION COMMITTED:',
                        value: detail.categories.join(', '),
                      ),
                    VendorTicketPaperField(
                      label: 'DESCRIPTION:',
                      value: detail.description,
                    ),
                    if (!warning) ...[
                      const Divider(),
                      const VendorTicketPaperSectionTitle(
                        icon: Icons.payments_outlined,
                        title: 'PENALTY DETAILS',
                      ),
                    ],
                    if (detail.severity != null)
                      VendorTicketPaperField(
                        label: 'SEVERITY:',
                        value: detail.severity!,
                        valueWidget: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: AppTheme.inspectionSeverityBackground(
                                detail.severity!,
                              ),
                            ),
                            child: Text(
                              detail.severity!,
                              style: TextStyle(
                                color: AppTheme.inspectionSeverityColor(
                                  detail.severity!,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (!warning) ...[
                      if (detail.penaltyType != null)
                        VendorTicketPaperField(
                          label: 'PENALTY TYPE:',
                          value: penalty?.label ?? detail.penaltyType!,
                        ),
                      if (detail.dueDate != null)
                        VendorTicketPaperField(
                          label: 'DUE DATE:',
                          value: DateTimeFormatter.getShortDate(
                            detail.dueDate!,
                          ),
                        ),
                      if (detail.totalFine != null)
                        Container(
                          width: double.infinity,
                          padding: AppTheme.ticketCardPadding,
                          decoration: const BoxDecoration(
                            color: AppColors.tertiary,
                            borderRadius: AppTheme.ticketCardRadius,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Fine Due:',
                                style: AppTheme.ticketHeadingStyle,
                              ),
                              const SizedBox(height: AppTheme.ticketTinyGap),
                              Text(
                                '₱${detail.totalFine!.toStringAsFixed(2)}',
                                style: AppTheme.detailTitleStyle.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (detail.communityServiceHours != null)
                        VendorTicketPaperField(
                          label: 'COMMUNITY SERVICE HOURS:',
                          value: '${detail.communityServiceHours}',
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.ticketSmallGap),
              const Divider(height: AppTheme.ticketSmallGap),
              const SizedBox(height: AppTheme.ticketSmallGap),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.ticketCardPadding.left,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppTheme.ticketSmallGap,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(),
                          Text('Issued By:'),
                          Text(
                            'Market Officer',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Marikina City Public Market'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          const Text('Issued To:'),
                          const Text(
                            'Market Vendor',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Date: ${DateTimeFormatter.getDate(detail.issuedAt)}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.ticketSmallGap),
        VendorRecordEvidenceSection(urls: detail.evidenceUrls),
      ],
    );
  }
}
