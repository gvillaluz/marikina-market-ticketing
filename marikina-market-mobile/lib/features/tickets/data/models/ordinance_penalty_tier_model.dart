import '../../domain/entities/ordinance_penalty_tier.dart';
import '../../domain/enums/fine_kind.dart';

class OrdinancePenaltyTierModel {
  final Map<String, Object?> values;
  const OrdinancePenaltyTierModel._(this.values);

  factory OrdinancePenaltyTierModel.fromJson(Map<String, Object?> json) =>
      OrdinancePenaltyTierModel._(Map.unmodifiable(json));

  Map<String, Object?> toJson() => Map.of(values);

  OrdinancePenaltyTier toEntity() => OrdinancePenaltyTier(
    id: values['id'] as int,
    offenseNumber: values['offense_number'] as int,
    fineKind: FineKind.fromValue(values['fine_kind']),
    penaltyAmount: (values['penalty_amount'] as num?)?.toDouble(),
    minimumFine: (values['minimum_fine'] as num?)?.toDouble(),
    maximumFine: (values['maximum_fine'] as num?)?.toDouble(),
    penaltyTerms: values['penalty_terms'] as String?,
    allowBloodDonation: values['allow_blood_donation'] as bool? ?? false,
    allowCommunityService: values['allow_community_service'] as bool? ?? false,
  );
}
