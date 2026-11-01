import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_breakdown_item.dart';
import '../enums/fine_kind.dart';

class FineSummary {
  final double? totalPaymentAmount;
  final Severity? severity;
  final List<FineBreakdownItem> breakdownItems;
  final bool allowBloodDonation, allowCommunityService;

  FineSummary({
    required this.totalPaymentAmount,
    required this.severity,
    required this.breakdownItems,
    this.allowBloodDonation = false,
    this.allowCommunityService = false,
  });

  bool get isAssessable =>
      severity != null &&
      breakdownItems.isNotEmpty &&
      breakdownItems.every(
        (item) =>
            !item.isDuplicate &&
            item.severity != null &&
            item.hasConfirmedAmount,
      );

  FineSummary withAssessments(Map<int, double> amounts) {
    final items = breakdownItems
        .map(
          (item) => item.fineKind == FineKind.upTo
              ? item.withPaymentAmount(amounts[item.ordinanceId])
              : item,
        )
        .toList();
    final scores =
        items.map((item) => item.severity).whereType<Severity>().toList()
          ..sort();
    final score = scores.isNotEmpty && scores.length == items.length
        ? scores.last
        : null;
    final complete =
        items.isNotEmpty &&
        items.every(
          (item) =>
              !item.isDuplicate &&
              item.hasConfirmedAmount &&
              item.severity != null,
        );
    return FineSummary(
      totalPaymentAmount: complete
          ? double.parse(
              items
                  .fold<double>(0, (total, item) => total + item.paymentAmount!)
                  .toStringAsFixed(2),
            )
          : null,
      severity: score,
      breakdownItems: items,
      allowBloodDonation:
          items.isNotEmpty &&
          items.every(
            (item) =>
                item.fineKind != FineKind.unconfirmed &&
                item.offenseNumber == 1 &&
                item.allowBloodDonation,
          ),
      allowCommunityService:
          items.isNotEmpty &&
          items.every(
            (item) =>
                item.fineKind != FineKind.unconfirmed &&
                item.offenseNumber == 1 &&
                item.allowCommunityService,
          ),
    );
  }
}
