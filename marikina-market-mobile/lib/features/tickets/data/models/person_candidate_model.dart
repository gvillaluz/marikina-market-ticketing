import 'package:marikina_market_mobile/features/tickets/domain/entities/person_candidate.dart';

class PersonCandidateModel {
  final int id;
  final String fullName, address;
  final String? phoneNumber;
  final List<String> matchedFields;
  const PersonCandidateModel({
    required this.id,
    required this.fullName,
    required this.address,
    this.phoneNumber,
    this.matchedFields = const [],
  });
  factory PersonCandidateModel.fromJson(Map<String, Object?> json) =>
      PersonCandidateModel(
        id: json['id'] as int,
        fullName: json['full_name'] as String,
        address: json['address'] as String,
        phoneNumber: json['phone_number'] as String?,
        matchedFields: (json['matched_fields'] as List<Object?>? ?? [])
            .cast<String>(),
      );
  PersonCandidate toEntity() => PersonCandidate(
    id: id,
    fullName: fullName,
    address: address,
    phoneNumber: phoneNumber,
    matchedFields: matchedFields,
  );
}
