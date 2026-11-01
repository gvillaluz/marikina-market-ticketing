class ViolationSummary {
  final int ordinanceId;
  final String ordinanceNo;
  final String series;
  final String? section;
  final String? specificCategory;

  String get detailsLabel =>
      specificCategory == null || specificCategory!.isEmpty
      ? sectionLabel
      : "$sectionLabel · $specificCategory";

  String get sectionLabel => section == null || section!.isEmpty
      ? 'Section unavailable'
      : "Section $section";
  final double? paymentAmount;
  final int offenseNumber;

  ViolationSummary({
    required this.ordinanceId,
    required this.ordinanceNo,
    this.series = '',
    required this.section,
    this.specificCategory,
    this.paymentAmount,
    required this.offenseNumber,
  });
}
