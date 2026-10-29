class VendorProfile {
  final int vendorId;
  final String businessAccountNumber;
  final String businessName;
  final String? stallNumber;
  final int marketSectionId;
  final String? marketSectionName;
  final String type;
  final String status;
  final String qrCodeValue;
  final int? complianceScore;
  final DateTime? scoreUpdatedAt;
  final DateTime? createdAt;

  const VendorProfile({
    required this.vendorId,
    required this.businessAccountNumber,
    required this.businessName,
    required this.stallNumber,
    required this.marketSectionId,
    required this.marketSectionName,
    required this.type,
    required this.status,
    required this.qrCodeValue,
    this.complianceScore,
    this.scoreUpdatedAt,
    this.createdAt,
  });
}
