import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/core/utils/date_formatter_util.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/detail_row.dart';

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

  @override
  Widget build(BuildContext context) {
    final penalty =
        penaltyType == PenaltyType.communityService && communityHrs != null
        ? '${penaltyType.value} ($communityHrs hrs)'
        : penaltyType.value;

    return Column(
      children: [
        Wrap(
          spacing: AppTheme.ticketSmallGap,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Text(
                '₱',
                style: TextStyle(color: AppColors.primaryLight, fontSize: 16),
              ),
            ),
            const Text(
              'PENALTY DETAILS',
              style: TextStyle(fontSize: 18, color: AppColors.primary),
            ),
          ],
        ),

        const SizedBox(height: 20),

        Column(
          spacing: AppTheme.ticketSmallGap,
          children: [
            Wrap(
              children: [
                const Text('SEVERITY:'),
                Container(
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
              ],
            ),
            DetailRow(label: 'PENALTY TYPE:', value: penalty),
            DetailRow(
              label: 'DUE DATE:',
              value:
                  '${DateTimeFormatter.getDate(dueDate)}, (15 days from issuance)',
            ),
          ],
        ),

        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.tertiary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              const Text(
                'Total Fine Due:',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _currencyFormat.format(totalFineAmount),
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
