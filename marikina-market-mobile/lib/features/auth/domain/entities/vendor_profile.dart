class VendorProfile {
  final int vendorId;
  final String businessId;
  final String businessName;
  final String? stallNumber;
  final int marketSectionId;
  final String? marketSectionName;
  final String type;
  final String status;
  final String qrCodeValue;
  final int? complianceScore;
  final DateTime? scoreUpdatedAt;
  final DateTime? registeredAt;

  const VendorProfile({
    required this.vendorId,
    required this.businessId,
    required this.businessName,
    required this.stallNumber,
    required this.marketSectionId,
    required this.marketSectionName,
    required this.type,
    required this.status,
    required this.qrCodeValue,
    this.complianceScore,
    this.scoreUpdatedAt,
    this.registeredAt,
  });
}
