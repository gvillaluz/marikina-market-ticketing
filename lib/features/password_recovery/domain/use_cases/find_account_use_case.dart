import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/entities/account_lookup.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/repositories/password_recovery_repository.dart';

class FindAccountUseCase {
  final PasswordRecoveryRepository _repository;
  FindAccountUseCase(this._repository);

  Future<Result<AccountLookup>> call(String username) async =>
      await _repository.findAccount(username);
}
