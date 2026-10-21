enum OrdinanceCategory {
  traffic("Traffic"),
  obstruction("Obstruction"),
  sanitation("Sanitation"),
  licensing("Licensing"),
  noise("Noise"),
  weightmeasures("WeightMeasures");

  final String value;
  const OrdinanceCategory(this.value);

  static OrdinanceCategory fromValue(String value) {
    return OrdinanceCategory.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw ArgumentError('Unknown category: $value'),
    );
  }
}