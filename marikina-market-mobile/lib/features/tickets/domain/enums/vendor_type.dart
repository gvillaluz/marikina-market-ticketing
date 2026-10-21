enum VendorType {
  public("Public"),
  private("Private");

  final String value;
  const VendorType(this.value);

  static VendorType fromValue(String value) {
    return VendorType.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw ArgumentError('Unknown vendor type: $value'),
    );
  }
}
