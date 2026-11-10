import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/utils/extentions/integer_extensions.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_summary.dart';

// The enforcer copies the entry page's fine and offense positions onto the
// paper. Verify works them out again on the server. When the answer differs
// from what was copied, this says what to write instead. It only warns.
class FineChangedNotice extends StatelessWidget {
  final FineSummary? copied;
  final FineSummary? verified;
  final PenaltyType? penaltyType;

  const FineChangedNotice({
    required this.copied,
    required this.verified,
    required this.penaltyType,
    super.key,
  });

  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
  );

  List<String> get _messages {
    final before = copied;
    final now = verified;
    if (before == null || now == null) return const [];

    final messages = <String>[];
    final copiedTotal = before.totalPaymentAmount;
    final verifiedTotal = now.totalPaymentAmount;
    if (penaltyType == PenaltyType.cashFine &&
        copiedTotal != null &&
        verifiedTotal != null &&
        copiedTotal != verifiedTotal) {
      messages.add(
        'The fine changed after you copied it. Write '
        '${_currencyFormat.format(verifiedTotal)} on the paper ticket instead '
        'of ${_currencyFormat.format(copiedTotal)}.',
      );
    }
    for (final item in now.breakdownItems) {
      for (final earlier in before.breakdownItems) {
        if (earlier.ordinanceId == item.ordinanceId &&
            earlier.offenseNumber != item.offenseNumber) {
          messages.add(
            '${item.sectionLabel} is now the '
            '${item.offenseNumber.toOrdinal()} offense, not the '
            '${earlier.offenseNumber.toOrdinal()}.',
          );
        }
      }
    }
    return messages;
  }

  @override
  Widget build(BuildContext context) {
    final messages = _messages;
    if (messages.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppTheme.inspectionSmallGap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppTheme.inspectionSmallGap,
        children: [
          for (final message in messages)
            Text(
              message,
              style: const TextStyle(
                color: AppColors.primaryRed,
                fontSize: AppTheme.bodyFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}
