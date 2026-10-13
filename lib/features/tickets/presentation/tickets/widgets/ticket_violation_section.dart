import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

import 'package:intl/intl.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/utils/date_formatter_util.dart';
import 'package:marikina_market_mobile/core/utils/extentions/integer_extensions.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/violation_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/ordinance_category.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/detail_row.dart';

class TicketViolationSection extends StatelessWidget {
  final List<ViolationSummary> violations;
  final String description;
  final String marketSection;
  final List<OrdinanceCategory> categories;
  final bool isTicket;

  const TicketViolationSection({
    required this.violations,
    required this.description,
    required this.marketSection,
    required this.categories,
    required this.isTicket,
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
        const Wrap(
          spacing: AppTheme.ticketTinyGap,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(Icons.warning, color: AppColors.primary),
            Text(
              'VIOLATION DETAILS',
              style: TextStyle(color: AppColors.primary, fontSize: 18),
            ),
          ],
        ),

        const SizedBox(height: 20),

        const Text('ORDINANCE:', style: TextStyle(fontWeight: FontWeight.bold)),

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
                    ordinance.ordinanceNo,
                    style: const TextStyle(fontSize: 15),
                  ),
                  Text(
                    ordinance.ordinanceCode,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1,
                      color: AppColors.mediumGrey,
                    ),
                  ),

                  if (isTicket) ...[
                    const SizedBox(height: 20),
                    Wrap(
                      children: [
                        Container(
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
                                  color: _getFontColor(ordinance.offenseNumber),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _currencyFormat.format(ordinance.paymentAmount),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        Column(
          spacing: AppTheme.ticketSmallGap,
          children: [
            DetailRow(
              label: 'DATE & TIME:',
              value: DateTimeFormatter.getDateTime(DateTime.now()),
            ),
            DetailRow(label: 'LOCATION:', value: marketSection),
            DetailRow(
              label: 'VIOLATION COMMITTED:',
              value: categories.map((c) => c.value).join(', '),
            ),

            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DESCRIPTION:'),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    softWrap: true,
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
