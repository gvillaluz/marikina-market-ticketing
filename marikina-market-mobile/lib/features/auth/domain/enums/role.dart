enum Role {
  headAdmin('HeadAdmin'),
  adminOfficer('AdminOfficer'),
  marketEnforcer('MarketEnforcer'),
  marketVendor('MarketVendor');

  final String value;
  const Role(this.value);

  static Role fromValue(String value) {
    return Role.values.firstWhere(
      (role) => role.value == value,
      orElse: () => throw ArgumentError('Unknown role: $value'),
    );
  }
}
