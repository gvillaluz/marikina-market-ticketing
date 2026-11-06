import 'package:marikina_market_mobile/features/tickets/domain/entities/ordinance_shortcuts.dart';

class OrdinanceShortcutsModel {
  final List<int> personOrdinanceIds;
  final List<int> myRecentOrdinanceIds;
  final List<int> mostViolatedOrdinanceIds;
  const OrdinanceShortcutsModel({
    required this.personOrdinanceIds,
    required this.myRecentOrdinanceIds,
    required this.mostViolatedOrdinanceIds,
  });
  factory OrdinanceShortcutsModel.fromJson(Map<String, Object?> json) =>
      OrdinanceShortcutsModel(
        personOrdinanceIds: _ids(json['person_ordinance_ids']),
        myRecentOrdinanceIds: _ids(json['my_recent_ordinance_ids']),
        mostViolatedOrdinanceIds: _ids(json['most_violated_ordinance_ids']),
      );
  static List<int> _ids(Object? value) => (value as List<Object?>).cast<int>();
  OrdinanceShortcuts toEntity() => OrdinanceShortcuts(
    personOrdinanceIds: personOrdinanceIds,
    myRecentOrdinanceIds: myRecentOrdinanceIds,
    mostViolatedOrdinanceIds: mostViolatedOrdinanceIds,
  );
}
