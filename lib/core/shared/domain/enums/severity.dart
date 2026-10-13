enum Severity implements Comparable<Severity> {
  minor("Minor"),
  moderate("Moderate"),
  high("High");

  final String value;
  const Severity(this.value);

  static Severity fromValue(String value) {
    return Severity.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw ArgumentError('Unknown severity: $value'),
    );
  }

  @override
  int compareTo(Severity other) => index.compareTo(other.index);
}
