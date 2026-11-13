enum AccountStatus {
  active('Active'),
  deactivated('Deactivated');

  final String value;
  const AccountStatus(this.value);

  static AccountStatus fromValue(String value) {
    return AccountStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw ArgumentError('Unknown status: $value'),
    );
  }
}