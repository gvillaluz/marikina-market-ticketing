import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import '../enums/fine_kind.dart';

class FineBreakdownItem {
  final int ordinanceId;
  final String ordinanceNo;
  final String? section;
  final String? specificCategory;

  String get detailsLabel =>
      specificCategory == null || specificCategory!.isEmpty
      ? sectionLabel
      : "$sectionLabel · $specificCategory";

  String get sectionLabel => section == null || section!.isEmpty
      ? 'Section unavailable'
      : "Section $section";
  final double? paymentAmount;
  final Severity? severity;
  final FineKind fineKind;
  final double? minimumFine, maximumFine;
  final String? penaltyTerms;
  final bool allowBloodDonation, allowCommunityService;
  final int offenseNumber;
  final bool isDuplicate;

  bool get hasConfirmedAmount {
    final amount = paymentAmount;
    if (amount == null ||
        !amount.isFinite ||
        amount < 0 ||
        (amount - double.parse(amount.toStringAsFixed(2))).abs() > 0.00000001) {
      return false;
    }
    return switch (fineKind) {
      FineKind.fixed => true,
      FineKind.upTo =>
        minimumFine != null &&
            maximumFine != null &&
            minimumFine!.isFinite &&
            maximumFine!.isFinite &&
            amount >= minimumFine! &&
            amount <= maximumFine!,
      FineKind.unconfirmed => false,
    };
  }

  FineBreakdownItem({
    required this.ordinanceId,
    required this.ordinanceNo,
    required this.section,
    this.specificCategory,
    required this.paymentAmount,
    required this.severity,
    required this.offenseNumber,
    required this.isDuplicate,
    this.fineKind = FineKind.unconfirmed,
    this.minimumFine,
    this.maximumFine,
    this.penaltyTerms,
    this.allowBloodDonation = false,
    this.allowCommunityService = false,
  });

  FineBreakdownItem withPaymentAmount(double? amount) => FineBreakdownItem(
    ordinanceId: ordinanceId,
    ordinanceNo: ordinanceNo,
    section: section,
    specificCategory: specificCategory,
    paymentAmount: amount,
    severity: severity,
    offenseNumber: offenseNumber,
    isDuplicate: isDuplicate,
    fineKind: fineKind,
    minimumFine: minimumFine,
    maximumFine: maximumFine,
    penaltyTerms: penaltyTerms,
    allowBloodDonation: allowBloodDonation,
    allowCommunityService: allowCommunityService,
  );
}
