import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ordinance.dart';
import 'package:marikina_market_mobile/features/tickets/domain/repositories/inspection_repository.dart';

class LoadOrdinancesUseCase {
  final InspectionRepository _repository;
  LoadOrdinancesUseCase(this._repository);

  Future<Result<List<Ordinance>>> call() async {
    return await _repository.loadOrdinances();
  }
}