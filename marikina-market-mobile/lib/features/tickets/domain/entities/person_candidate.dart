class PersonCandidate {
  final int id;
  final String fullName, address;
  final String? phoneNumber;
  final List<String> matchedFields;
  const PersonCandidate({
    required this.id,
    required this.fullName,
    required this.address,
    this.phoneNumber,
    this.matchedFields = const [],
  });
}
