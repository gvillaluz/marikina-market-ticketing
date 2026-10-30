import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/utils/date_formatter_util.dart';
import 'package:marikina_market_mobile/core/utils/extentions/integer_extensions.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_breakdown_item.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ordinance.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_field.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_section_title.dart';

class ViolationDetailsSection extends StatelessWidget {
  final String? issuePlace;
  final FineSummary? fine;
  final List<Ordinance> ordinances;
  final bool isTicket;
  final PenaltyType? penaltyType;
  final String marketSection;
  final String description;

  const ViolationDetailsSection({
    this.issuePlace,
    this.fine,
    required this.ordinances,
    required this.isTicket,
    this.penaltyType,
    required this.marketSection,
    required this.description,
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

  FineBreakdownItem? _breakdownFor(Ordinance ordinance) {
    if (fine == null) return null;
    for (final item in fine!.breakdownItems) {
      if (item.ordinanceId == ordinance.id) return item;
    }
    return null;
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
          itemCount: ordinances.length,
          itemBuilder: (context, index) {
            final ordinance = ordinances[index];
            final breakdown = _breakdownFor(ordinance);

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
                  const SizedBox(height: AppTheme.inspectionTinyGap),
                  Text(
                    ordinance.ordinanceCode,
                    style: const TextStyle(
                      fontSize: AppTheme.captionFontSize,
                      height: 1,
                      color: AppColors.mediumGrey,
                    ),
                  ),

                  if (isTicket && breakdown != null) ...[
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
                              color: _getBgColor(breakdown.offenseNumber),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Wrap(
                              spacing: AppTheme.inspectionTinyGap,
                              children: [
                                Icon(
                                  Icons.restore_outlined,
                                  color: _getFontColor(breakdown.offenseNumber),
                                  size: 15,
                                ),
                                Text(
                                  '${breakdown.offenseNumber.toOrdinal()} offense',
                                  style: TextStyle(
                                    color: _getFontColor(
                                      breakdown.offenseNumber,
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
                              _currencyFormat.format(breakdown.paymentAmount),
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
          spacing: AppTheme.inspectionSmallGap,
          children: [
            TicketPaperField(
              label: 'DATE & TIME:',
              value: isTicket
                  ? DateTimeFormatter.getDateTime(DateTime.now())
                  : 'Assigned when saved',
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
              value: ordinances
                  .map((o) => o.category.value)
                  .toList()
                  .join(', '),
            ),

            TicketPaperField(label: 'DESCRIPTION:', value: description),
          ],
        ),
      ],
    );
  }
}
