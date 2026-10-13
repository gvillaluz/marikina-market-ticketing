enum ViolationType {
  warning('Warning'),
  ticket('Ticket');

  final String value;
  const ViolationType(this.value);

  static ViolationType fromValue(String value) {
    return ViolationType.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw ArgumentError('Unknown type: $value'),
    );
  }
}