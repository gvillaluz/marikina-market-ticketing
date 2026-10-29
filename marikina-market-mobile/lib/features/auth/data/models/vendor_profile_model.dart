import 'package:marikina_market_mobile/features/auth/domain/entities/vendor_profile.dart';

class VendorProfileModel {
  final VendorProfile profile;
  const VendorProfileModel(this.profile);

  factory VendorProfileModel.fromJson(Map<String, Object?> json) =>
      VendorProfileModel(
        VendorProfile(
          vendorId: json['vendor_id'] as int,
          businessAccountNumber: json['business_account_number'] as String,
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
          createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
        ),
      );

  Map<String, Object?> toJson() => {
    'vendor_id': profile.vendorId,
    'business_account_number': profile.businessAccountNumber,
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
    if (profile.createdAt != null)
      'created_at': profile.createdAt!.toIso8601String(),
  };

  VendorProfile toEntity() => profile;
}
