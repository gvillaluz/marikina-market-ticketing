import 'package:marikina_market_mobile/features/tickets/domain/entities/vendor_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/business_type.dart';

class VendorSummaryModel {
  final int id;
  final String? username;
  final BusinessType type;
  final String businessAccountNumber;
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
    required this.businessAccountNumber,
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
      username: json['username'] as String?,
      type: _parseBusinessType(json['type']),
      businessAccountNumber: json['business_account_number'] as String,
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

  static BusinessType _parseBusinessType(Object? value) {
    if (value is String) return BusinessType.fromValue(value);
    if (value is int && value >= 0 && value < BusinessType.values.length) {
      return BusinessType.values[value];
    }
    throw FormatException('Invalid business type: $value');
  }

  VendorSummary toEntity() {
    return VendorSummary(
      id: id,
      username: username,
      type: type,
      businessAccountNumber: businessAccountNumber,
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
