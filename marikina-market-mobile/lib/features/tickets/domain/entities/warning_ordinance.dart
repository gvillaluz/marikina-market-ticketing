class WarningOrdinance {
  final int ordinanceId;
  final String ordinanceNo;
  final String? section;
  final String? specificCategory;

  String get detailsLabel =>
      specificCategory == null || specificCategory!.isEmpty
      ? sectionLabel
      : "$sectionLabel · $specificCategory";

  String get sectionLabel => section == null || section!.isEmpty
      ? 'Section unavailable'
      : "Section $section";

  const WarningOrdinance({
    required this.ordinanceId,
    required this.ordinanceNo,
    required this.section,
    this.specificCategory,
  });
}
