import 'package:marikina_market_mobile/features/tickets/domain/entities/market_section.dart';

class MarketSectionModel {
  final int id;
  final String name;
  final bool isActive;

  const MarketSectionModel({
    required this.id,
    required this.name,
    required this.isActive,
  });

  factory MarketSectionModel.fromJson(Map<String, Object?> json) =>
      MarketSectionModel(
        id: json['id'] as int,
        name: json['name'] as String,
        isActive: json['is_active'] as bool,
      );

  MarketSection toEntity() => MarketSection(id: id, name: name);
}
