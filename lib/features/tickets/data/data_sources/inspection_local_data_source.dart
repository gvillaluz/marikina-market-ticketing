import 'package:hive_flutter/hive_flutter.dart';
import 'package:marikina_market_mobile/core/errors/exceptions.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_hive_model.dart';

abstract class InspectionLocalDataSource {
  Future<List<OrdinanceHiveModel>> getCacheOrdinances();
  Future<void> saveOrdinances(List<OrdinanceHiveModel> ordinances);
}

class InspectionLocalDataSourceImpl implements InspectionLocalDataSource {
  final Box<OrdinanceHiveModel> _box;
  InspectionLocalDataSourceImpl(this._box);

  @override
  Future<List<OrdinanceHiveModel>> getCacheOrdinances() async {
    try {
      return _box.values.toList();
    } catch (e) {
      throw CacheException('Failed to read cached ordinances: $e');
    }
  }

  @override
  Future<void> saveOrdinances(List<OrdinanceHiveModel> ordinances) async {
    try {
      await _box.clear();
      await _box.addAll(ordinances);
    } catch (e) {
      throw CacheException('Failed to save ordinances: $e');
    }
  }
}