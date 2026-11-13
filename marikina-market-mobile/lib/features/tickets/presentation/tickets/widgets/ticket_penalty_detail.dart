import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/core/utils/date_formatter_util.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_field.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_field_group.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_section_title.dart';

class TicketPenaltyDetail extends StatelessWidget {
  final Severity severity;
  final PenaltyType penaltyType;
  final DateTime dueDate;
  final double? totalFineAmount;
  final int? communityHrs;

  const TicketPenaltyDetail({
    required this.severity,
    required this.penaltyType,
    required this.dueDate,
    this.totalFineAmount,
    this.communityHrs,
    super.key,
  });

  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
  );

  Color _getBgColor() {
    if (severity == Severity.high) {
      return AppColors.secondaryRed;
    } else if (severity == Severity.moderate) {
      return AppColors.primaryYellow;
    } else {
      return AppColors.tertiary;
    }
  }

  Color _getColor() {
    if (severity == Severity.high) {
      return AppColors.primaryRed;
    } else if (severity == Severity.moderate) {
      return AppColors.secondaryYellow;
    } else {
      return AppColors.primary;
    }
  }

  Widget _valueText(String value) => Text(
    value,
    textAlign: TextAlign.right,
    style: AppTheme.ticketPaperValueStyle,
  );

  @override
  Widget build(BuildContext context) {
    final penalty =
        penaltyType == PenaltyType.communityService && communityHrs != null
        ? '${penaltyType.value}\n($communityHrs hrs)'
        : penaltyType.value;

    final dueText =
        '${DateTimeFormatter.getDate(dueDate)}\n(5 days from issuance)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TicketPaperSectionTitle(
          icon: Icons.payments_outlined,
          title: 'PENALTY DETAILS',
        ),
        const SizedBox(height: AppTheme.ticketSmallGap),

        TicketPaperFieldGroup(
          spacing: AppTheme.ticketSmallGap,
          fields: [
            TicketPaperField(
              label: 'SEVERITY:',
              value: severity.value,
              valueWidget: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: _getBgColor(),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: Text(
                    severity.value,
                    style: TextStyle(color: _getColor()),
                  ),
                ),
              ),
            ),
            TicketPaperField(
              label: 'PENALTY TYPE:',
              value: penalty,
              valueWidget: _valueText(penalty),
            ),
            TicketPaperField(
              label: 'DUE DATE:',
              value: dueText,
              valueWidget: _valueText(dueText),
            ),
          ],
        ),

        if (penaltyType == PenaltyType.cashFine) ...[
          const SizedBox(height: AppTheme.ticketSmallGap),

          Container(
            width: double.infinity,
            padding: AppTheme.ticketCardPadding,
            decoration: BoxDecoration(
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
                  _currencyFormat.format(totalFineAmount),
                  style: AppTheme.detailTitleStyle.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
