import '../enums/fine_kind.dart';

class OrdinancePenaltyTier {
  final int id, offenseNumber;
  final FineKind fineKind;
  final double? penaltyAmount, minimumFine, maximumFine;
  final String? penaltyTerms;
  final bool allowBloodDonation, allowCommunityService;

  const OrdinancePenaltyTier({
    required this.id,
    required this.offenseNumber,
    required this.fineKind,
    this.penaltyAmount,
    this.minimumFine,
    this.maximumFine,
    this.penaltyTerms,
    this.allowBloodDonation = false,
    this.allowCommunityService = false,
  });
}
