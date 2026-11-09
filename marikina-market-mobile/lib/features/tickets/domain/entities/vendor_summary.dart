import 'package:marikina_market_mobile/features/tickets/domain/entities/market_section.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/business_type.dart';

class VendorSummary {
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

  const VendorSummary({
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

  String get ownerName => [
    firstName,
    middleName,
    lastName,
  ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');

  MarketSection get marketSection =>
      MarketSection(id: marketSectionId, name: marketSectionName);

  // Where the ticket is issued, filled in from the business record.
  String get issuePlace => [
    marketSectionName,
    if (stallNumber != null) 'Stall $stallNumber',
  ].join(', ');
}
