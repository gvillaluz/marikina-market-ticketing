class RecordViolation {
  final String ordinanceNumber;
  final String? section;
  final String? specificCategory;

  String get detailsLabel =>
      specificCategory == null || specificCategory!.isEmpty
      ? sectionLabel
      : "$sectionLabel · $specificCategory";

  String get sectionLabel => section == null || section!.isEmpty
      ? 'Section unavailable'
      : "Section $section";
  final int offenseCount;
  final double? penaltyAmount;
  const RecordViolation({
    required this.ordinanceNumber,
    required this.section,
    this.specificCategory,
    required this.offenseCount,
    required this.penaltyAmount,
  });
}
