import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/utils/date_formatter_util.dart';
import 'package:marikina_market_mobile/core/utils/extentions/integer_extensions.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_breakdown_item.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ordinance.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/detail_row.dart';

class ViolationDetailsSection extends StatelessWidget {
  final FineSummary? fine;
  final List<Ordinance> ordinances;
  final bool isTicket;
  final String marketSection;
  final String description;

  const ViolationDetailsSection({
    this.fine,
    required this.ordinances,
    required this.isTicket,
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
        const Wrap(
          spacing: AppTheme.inspectionTinyGap,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(Icons.warning, color: AppColors.primary),
            Text(
              'VIOLATION DETAILS',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: AppTheme.sectionHeadingFontSize,
              ),
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
                  Text(
                    ordinance.ordinanceCode,
                    style: const TextStyle(
                      fontSize: AppTheme.captionFontSize,
                      height: 1,
                      color: AppColors.mediumGrey,
                    ),
                  ),

                  if (isTicket && breakdown != null) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
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
                                  color: _getFontColor(breakdown.offenseNumber),
                                  fontSize: AppTheme.captionFontSize,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _currencyFormat.format(breakdown.paymentAmount),
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
          spacing: AppTheme.inspectionSmallGap,
          children: [
            DetailRow(
              label: 'DATE & TIME:',
              value: DateTimeFormatter.getDateTime(DateTime.now()),
            ),
            DetailRow(label: 'LOCATION:', value: marketSection),
            DetailRow(
              label: 'VIOLATION COMMITTED:',
              value: ordinances
                  .map((o) => o.category.value)
                  .toList()
                  .join(', '),
            ),

            DetailRow(label: 'DESCRIPTION:', value: description),
          ],
        ),
      ],
    );
  }
}
