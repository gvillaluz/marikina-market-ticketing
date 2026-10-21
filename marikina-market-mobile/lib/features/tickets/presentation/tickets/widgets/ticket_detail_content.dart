import 'dart:io';

import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_notice.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/core/utils/date_formatter_util.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/submit_community_service_log_params.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_detail_content_data.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_detail_evidence_section.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_penalty_detail.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_settlement_section.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_violation_section.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/violator_detail_section.dart';

class TicketDetailContent extends StatelessWidget {
  final TicketDetailContentData data;
  final VoidCallback onRetrySettlementLoad;
  final ValueChanged<File> onSubmitReceipt;
  final ValueChanged<SubmitCommunityServiceLogParams>
  onSubmitCommunityServiceLog;

  const TicketDetailContent({
    required this.data,
    required this.onSubmitReceipt,
    required this.onSubmitCommunityServiceLog,
    required this.onRetrySettlementLoad,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ticket = data.ticket;
    final droppedOrdinances = data.droppedOrdinances;
    bool isTicket = ticket.violationType == ViolationType.ticket;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (droppedOrdinances != null && droppedOrdinances.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryYellow, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.secondaryYellow,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '!',
                        style: TextStyle(
                          color: AppColors.secondaryYellow,
                          fontWeight: FontWeight.bold,
                          fontSize: AppTheme.bodyFontSize,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ordinance Skipped',
                            style: TextStyle(
                              color: AppColors.secondaryYellow,
                              fontWeight: FontWeight.bold,
                              fontSize: AppTheme.sectionHeadingFontSize,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This vendor already has an open ticket for multiple ordinance, so it wasn\'t added again.',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: AppTheme.captionFontSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Container(
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryYellow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primaryYellow,
                      width: 1,
                    ),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.primaryYellow,
                    ),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: droppedOrdinances.length,
                    itemBuilder: (context, index) => ListTile(
                      title: Text(
                        droppedOrdinances[index].ordinanceNo,
                        style: const TextStyle(
                          fontSize: AppTheme.bodyFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        droppedOrdinances[index].ordinanceCode,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: AppTheme.captionFontSize,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],

        Text(
          isTicket ? 'Ticket Record' : 'Written Warning Record',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: AppTheme.detailTitleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          isTicket
              ? 'Here is the record of the collected violation ticket, You can review the details below.'
              : 'Please review the details below before issuing the warning.',
        ),

        const SizedBox(height: 20),

        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.primaryLight,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .25),
                offset: const Offset(-1, 1),
                blurRadius: 3.5,
                spreadRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.only(top: 20, bottom: 20),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: Column(
                  children: [
                    const Text(
                      'City of Marikina',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: AppTheme.sectionHeadingFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Marikina Public Market Office'),

                    const SizedBox(height: 20),

                    Wrap(
                      spacing: AppTheme.ticketTinyGap,
                      children: [
                        Image.asset(
                          'assets/logo/org_logo.png',
                          height: 50,
                          width: 50,
                        ),
                        Text(
                          isTicket ? 'VIOLATION TICKET' : 'WRITTEN WARNING',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: AppTheme.sectionHeadingFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        if (isTicket) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'CONTROL NO.',
                                style: TextStyle(
                                  color: AppColors.mediumGrey,
                                  fontSize: AppTheme.captionFontSize,
                                ),
                              ),
                              Text(
                                '#${ticket.controlNumber!}',
                                style: TextStyle(
                                  color: AppColors.primaryRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: AppTheme.sectionHeadingFontSize,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const DottedLine(dashLength: 5, dashColor: AppColors.lightGrey),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: ViolatorDetailSection(
                  ticket: ticket,
                  isTicket: isTicket,
                ),
              ),

              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.only(left: 20, right: 20),
                child: Divider(),
              ),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: TicketViolationSection(
                  violations: ticket.violations,
                  description: ticket.description,
                  marketSection: ticket.marketSectionName,
                  categories: ticket.categories,
                  isTicket: isTicket,
                ),
              ),

              if (isTicket) ...[
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.only(left: 20, right: 20),
                  child: Divider(),
                ),
                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  child: TicketPenaltyDetail(
                    severity: ticket.severity ?? Severity.minor,
                    penaltyType: ticket.penaltyType ?? PenaltyType.cashFine,
                    totalFineAmount: ticket.totalFineAmount ?? 0.0,
                    dueDate: ticket.dueDate ?? DateTime.now(),
                    communityHrs: ticket.communityServiceHours,
                  ),
                ),
              ],

              const SizedBox(height: 20),
              const DottedLine(dashLength: 5, dashColor: AppColors.lightGrey),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppTheme.ticketSmallGap,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          const Text('Issued By:'),
                          const Text(
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
                            'Date: ${DateTimeFormatter.getDate(ticket.issuedAt)}',
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

        if (isTicket) ...[
          const SizedBox(height: 20),

          const Text(
            'Photo Evidence Record',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: AppTheme.sectionHeadingFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'The image below serves as the photo evidence attached to this violation ticket.',
          ),

          const SizedBox(height: 10),

          if (ticket.evidenceUrls == null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                border: Border.all(
                  color: AppColors.lightGrey.withValues(alpha: 0.5),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                    'No Photo Evidences Found',
                    style: TextStyle(
                      fontSize: AppTheme.sectionHeadingFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'There are no captured or recorded photo evidences for this ticket.',
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
          ] else ...[
            TicketDetailEvidenceSection(
              evidences: ticket.evidenceUrls!,
              isTicket: isTicket,
            ),
          ],

          if (isTicket && data.settlement != null) ...[
            const SizedBox(height: 20),
            TicketSettlementSection(
              settlement: data.settlement!,
              onRetryLoad: onRetrySettlementLoad,
              onSubmitReceipt: onSubmitReceipt,
              onSubmitCommunityServiceLog: onSubmitCommunityServiceLog,
            ),
          ],
          if (isTicket && data.settlement == null)
            const TicketNotice(
              title: 'Settlement unavailable',
              message:
                  'This ticket has no settlement status. Please reload its details before attempting settlement.',
              icon: Icons.info_outline,
            ),
        ],
      ],
    );
  }
}
