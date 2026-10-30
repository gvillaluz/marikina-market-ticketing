import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

import 'package:intl/intl.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/utils/date_formatter_util.dart';
import 'package:marikina_market_mobile/core/utils/extentions/integer_extensions.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/violation_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/ordinance_category.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_field.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_section_title.dart';

class TicketViolationSection extends StatelessWidget {
  final String? issuePlace;
  final DateTime? issuedAt;
  final List<ViolationSummary> violations;
  final String description;
  final String marketSection;
  final List<OrdinanceCategory> categories;
  final bool isTicket;
  final PenaltyType? penaltyType;

  const TicketViolationSection({
    this.issuePlace,
    this.issuedAt,
    required this.violations,
    required this.description,
    required this.marketSection,
    required this.categories,
    required this.isTicket,
    this.penaltyType,
    super.key,
  });

  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
  );

  Color _getBgColor(int count) {
    if (count > 2) {
      return const Color(0xFFFCEBEB);
    } else if (count > 1 && count < 3) {
      return const Color(0xFFFAEEDA);
    } else {
      return const Color(0xFFEAF3DE);
    }
  }

  Color _getFontColor(int count) {
    if (count > 2) {
      return const Color(0xFF791F1F);
    } else if (count > 1 && count < 3) {
      return const Color(0xFF633806);
    } else {
      return const Color(0xFF27500A);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TicketPaperSectionTitle(
          icon: Icons.receipt_long_outlined,
          title: 'VIOLATION DETAILS',
        ),
        const SizedBox(height: AppTheme.ticketSmallGap),

        const Text('ORDINANCE:', style: AppTheme.ticketPaperLabelStyle),

        const SizedBox(height: 10),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemCount: violations.length,
          itemBuilder: (context, index) {
            final ordinance = violations[index];

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.lightGrey, width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ord No. ${ordinance.ordinanceNo}, Series of ${ordinance.series}',
                    style: const TextStyle(fontSize: AppTheme.bodyFontSize),
                  ),
                  const SizedBox(height: AppTheme.ticketTinyGap),
                  Text(
                    ordinance.ordinanceCode,
                    style: const TextStyle(
                      fontSize: AppTheme.captionFontSize,
                      height: 1,
                      color: AppColors.mediumGrey,
                    ),
                  ),

                  if (isTicket) ...[
                    const SizedBox(height: AppTheme.ticketSmallGap),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _getBgColor(ordinance.offenseNumber),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Wrap(
                              spacing: AppTheme.ticketTinyGap,
                              children: [
                                Icon(
                                  Icons.restore_outlined,
                                  color: _getFontColor(ordinance.offenseNumber),
                                  size: 15,
                                ),
                                Text(
                                  '${ordinance.offenseNumber.toOrdinal()} offense',
                                  style: TextStyle(
                                    color: _getFontColor(
                                      ordinance.offenseNumber,
                                    ),
                                    fontSize: AppTheme.captionFontSize,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (penaltyType == PenaltyType.cashFine) ...[
                          const SizedBox(height: AppTheme.ticketTinyGap),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              _currencyFormat.format(ordinance.paymentAmount),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        ),

        const SizedBox(height: AppTheme.ticketSmallGap),

        Column(
          spacing: AppTheme.ticketSmallGap,
          children: [
            TicketPaperField(
              label: 'DATE & TIME:',
              value: isTicket
                  ? DateTimeFormatter.getDateTime(DateTime.now())
                  : (issuedAt == null
                        ? 'Unavailable (legacy record)'
                        : DateTimeFormatter.getDateTime(issuedAt!)),
            ),
            TicketPaperField(
              label: 'ISSUE PLACE:',
              value: issuePlace ?? 'Unavailable (legacy record)',
            ),
            TicketPaperField(
              label: isTicket ? 'MARKET SECTION:' : 'LOCATION:',
              value: marketSection,
            ),
            TicketPaperField(
              label: 'VIOLATION COMMITTED:',
              value: categories.map((c) => c.value).join(', '),
            ),

            TicketPaperField(label: 'DESCRIPTION:', value: description),
          ],
        ),
      ],
    );
  }
}
