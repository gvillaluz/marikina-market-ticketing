enum PenaltyType {
  cashFine("CashFine", 'Cash Fine'),
  bloodDonation("BloodDonation", 'Blood Donation'),
  communityService("CommunityService", 'Community Service');

  final String value;
  final String label;
  const PenaltyType(this.value, this.label);

  static PenaltyType fromValue(String value) {
    return PenaltyType.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw ArgumentError('Unknown penalty: $value'),
    );
  }
}
