enum OrdinanceCategory {
  traffic("Traffic"),
  obstruction("Obstruction"),
  sanitation("Sanitation"),
  licensing("Licensing"),
  noise("Noise"),
  weightmeasures("WeightMeasures"),
  dressCode("DressCode"),
  illegalVendor("IllegalVendor"),
  nonSmoking("NonSmoking"),
  others("Others");

  final String value;
  const OrdinanceCategory(this.value);

  String get label => switch (this) {
    weightmeasures => 'Weights & Measures',
    dressCode => 'Dress Code',
    illegalVendor => 'Illegal Vendor',
    nonSmoking => 'Non-Smoking',
    _ => value,
  };

  static OrdinanceCategory fromValue(String value) {
    return OrdinanceCategory.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw ArgumentError('Unknown category: $value'),
    );
  }
}
