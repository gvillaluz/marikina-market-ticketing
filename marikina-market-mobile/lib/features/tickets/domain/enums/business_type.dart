enum BusinessType {
  public("Public"),
  private("Private");

  final String value;
  const BusinessType(this.value);

  static BusinessType fromValue(String value) {
    return BusinessType.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw ArgumentError('Unknown business type: $value'),
    );
  }
}
