import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ordinance_shortcuts.dart';
import 'package:marikina_market_mobile/features/tickets/domain/repositories/inspection_repository.dart';

class GetOrdinanceShortcutsUseCase {
  final InspectionRepository _repository;
  const GetOrdinanceShortcutsUseCase(this._repository);
  Future<Result<OrdinanceShortcuts>> call(int? personId) =>
      _repository.getOrdinanceShortcuts(personId);
}
