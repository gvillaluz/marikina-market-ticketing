import 'package:marikina_market_mobile/features/auth/domain/entities/vendor_profile.dart';

class VendorProfileModel {
  final VendorProfile profile;
  const VendorProfileModel(this.profile);

  factory VendorProfileModel.fromJson(Map<String, Object?> json) =>
      VendorProfileModel(
        VendorProfile(
          vendorId: json['vendor_id'] as int,
          businessId: json['business_id'] as String,
          businessName: json['business_name'] as String,
          stallNumber: json['stall_number'] as String?,
          marketSectionId: json['market_section_id'] as int,
          marketSectionName: json['market_section_name'] as String?,
          type: json['type'] as String,
          status: json['status'] as String,
          qrCodeValue: json['qr_code_value'] as String? ?? '',
          complianceScore: json['compliance_score'] as int?,
          scoreUpdatedAt: DateTime.tryParse(
            json['score_updated_at'] as String? ?? '',
          ),
          registeredAt: DateTime.tryParse(
            json['registered_at'] as String? ?? '',
          ),
        ),
      );

  Map<String, Object?> toJson() => {
    'vendor_id': profile.vendorId,
    'business_id': profile.businessId,
    'business_name': profile.businessName,
    'stall_number': profile.stallNumber,
    'market_section_id': profile.marketSectionId,
    'market_section_name': profile.marketSectionName,
    'type': profile.type,
    'status': profile.status,
    'qr_code_value': profile.qrCodeValue,
    if (profile.complianceScore != null)
      'compliance_score': profile.complianceScore,
    if (profile.scoreUpdatedAt != null)
      'score_updated_at': profile.scoreUpdatedAt!.toIso8601String(),
    if (profile.registeredAt != null)
      'registered_at': profile.registeredAt!.toIso8601String(),
  };

  VendorProfile toEntity() => profile;
}
