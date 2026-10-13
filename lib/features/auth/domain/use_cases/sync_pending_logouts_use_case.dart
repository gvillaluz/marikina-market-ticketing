import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/utils/unit.dart';
import 'package:marikina_market_mobile/features/auth/domain/repositories/auth_repository.dart';

class SyncPendingLogoutsUseCase {
  final AuthRepository _repository;
  SyncPendingLogoutsUseCase(this._repository);

  Future<Result<Unit>> call() => _repository.syncPendingLogouts();
}
