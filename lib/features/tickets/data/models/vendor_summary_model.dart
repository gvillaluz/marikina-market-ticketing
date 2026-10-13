import 'package:marikina_market_mobile/features/tickets/domain/entities/vendor_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/vendor_type.dart';

class VendorSummaryModel {
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

  const VendorSummaryModel({
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

  factory VendorSummaryModel.fromJson(Map<String, dynamic> json) {
    return VendorSummaryModel(
      id: json['vendor_id'] as int,
      username: json['username'] as String,
      type: _parseVendorType(json['type']),
      businessId: json['business_id'] as String,
      stallNumber: json['stall_number'] as String?,
      tradeName: json['trade_name'] as String,
      lastName: json['last_name'] as String,
      firstName: json['first_name'] as String,
      middleName: json['middle_name'] as String?,
      address: json['address'] as String,
      marketSectionId: json['market_section_id'] as int,
      marketSectionName: json['market_section_name'] as String,
    );
  }

  static VendorType _parseVendorType(Object? value) {
    if (value is String) return VendorType.fromValue(value);
    if (value is int && value >= 0 && value < VendorType.values.length) {
      return VendorType.values[value];
    }
    throw FormatException('Invalid vendor type: $value');
  }

  VendorSummary toEntity() {
    return VendorSummary(
      id: id,
      username: username,
      type: type,
      businessId: businessId,
      stallNumber: stallNumber,
      tradeName: tradeName,
      lastName: lastName,
      firstName: firstName,
      middleName: middleName,
      address: address,
      marketSectionId: marketSectionId,
      marketSectionName: marketSectionName,
    );
  }
}
