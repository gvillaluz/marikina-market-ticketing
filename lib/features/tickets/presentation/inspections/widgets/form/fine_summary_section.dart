import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/utils/extentions/integer_extensions.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_breakdown_item.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ordinance.dart';

class FineSummarySection extends StatelessWidget {
  final List<Ordinance> items;
  final FineSummary? fineSummary;
  final bool isTicket;
  final ValueChanged<int> onDelete;

  const FineSummarySection({
    required this.items,
    required this.fineSummary,
    required this.isTicket,
    required this.onDelete,
    super.key
  });

  static final _currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

  Color _getBgColor(int count) {
    if (count > 2) {
      return Color(0xFFFCEBEB);
    } else if (count > 1 && count < 3) {
      return Color(0xFFFAEEDA);
    } else {
      return Color(0xFFEAF3DE);
    }
  }

  Color _getFontColor(int count) {
    if (count > 2) {
      return Color(0xFF791F1F);
    } else if (count > 1 && count < 3) {
      return Color(0xFF633806);
    } else {
      return Color(0xFF27500A);
    }
  }

  FineBreakdownItem? _breakdownFor(Ordinance ordinance) {
    if (fineSummary == null) return null;
    for (final item in fineSummary!.breakdownItems) {
      if (item.ordinanceId == ordinance.id) return item;
    }
    return null;
  }


  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 5,),
          itemBuilder: (context, index) {
            final ordinance = items[index];
            final breakdown = _breakdownFor(ordinance);
        
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primary,
                  width: 1
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ordinance.ordinanceNo,
                    style: TextStyle(
                      fontSize: 15,
                    ),
                    softWrap: true,
                  ),
        
                  Text(
                    ordinance.ordinanceCode,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1,
                      color: AppColors.mediumGrey
                    ),
                  ),
        
                  if (isTicket && breakdown != null) ...{
                    const SizedBox(height: 20,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getBgColor(breakdown.offenseNumber),
                            borderRadius: BorderRadius.circular(10)
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 5,
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
                                  fontSize: 12
                                ),
                              ),
                            ],
                          )
                        ),
                        Text(
                          _currencyFormat.format(breakdown.paymentAmount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ],
                    ),
                  }
                ]
              )
            );
          }
        ),

        if (isTicket) ...{
          const Divider(height: 30,),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                spacing: 10,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: AppColors.secondaryGreen
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      color: AppColors.primaryGreen
                    ),
                  ),
                  const Text(
                    'Total Fine Amount: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16
                    ),
                  ),
                ],
              ),

              Text(
                _currencyFormat.format(fineSummary?.totalPaymentAmount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16
                )
              ),
            ],
          )
        }
      ],
    );
  }
}