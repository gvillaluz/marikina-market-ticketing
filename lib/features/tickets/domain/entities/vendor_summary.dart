import 'package:marikina_market_mobile/features/tickets/domain/enums/vendor_type.dart';

class VendorSummary {
  final int id;
  final String username;
  final VendorType type;
  final String businessId;
  final String? stallNumber;
  final String tradeName;
  final String lastName;
  final String firstName;
  final String? middleName;
  final String address;
  final int marketSectionId;
  final String marketSectionName;

  const VendorSummary({
    required this.id,
    required this.username,
    required this.type,
    required this.businessId,
    required this.stallNumber,
    required this.tradeName,
    required this.lastName,
    required this.firstName,
    required this.middleName,
    required this.address,
    required this.marketSectionId,
    required this.marketSectionName,
  });
}
