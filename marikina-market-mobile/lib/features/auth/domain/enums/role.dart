enum Role {
  headAdmin('HeadAdmin'),
  adminOfficer('AdminOfficer'),
  marketEnforcer('MarketEnforcer'),
  marketVendor('MarketVendor');

  final String value;
  const Role(this.value);

  String get label => switch (this) {
    headAdmin => 'Head Admin',
    adminOfficer => 'Admin Officer',
    marketEnforcer => 'Market Enforcer',
    marketVendor => 'Market Vendor',
  };

  static Role fromValue(String value) {
    return Role.values.firstWhere(
      (role) => role.value == value,
      orElse: () => throw ArgumentError('Unknown role: $value'),
    );
  }
}
