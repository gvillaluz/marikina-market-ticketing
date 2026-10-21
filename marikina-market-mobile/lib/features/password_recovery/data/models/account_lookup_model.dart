import 'package:marikina_market_mobile/features/password_recovery/domain/entities/account_lookup.dart';

class AccountLookupModel {
  final bool found;
  final String maskedEmail;
  final String masketPhoneNumber;

  AccountLookupModel({
    required this.found,
    required this.maskedEmail,
    required this.masketPhoneNumber,
  });

  factory AccountLookupModel.fromJson(Map<String, dynamic> json) {
    return AccountLookupModel(
      found: json['found'] as bool,
      maskedEmail: json['masked_email'] as String,
      masketPhoneNumber: json['masked_phone_number'] as String,
    );
  }

  AccountLookup toEntity() {
    return AccountLookup(
      found: found,
      maskedEmail: maskedEmail,
      masketPhoneNumber: masketPhoneNumber,
    );
  }
}
