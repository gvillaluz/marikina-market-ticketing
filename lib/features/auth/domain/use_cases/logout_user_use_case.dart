import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/utils/unit.dart';
import 'package:marikina_market_mobile/features/auth/domain/repositories/auth_repository.dart';

class LogoutUserUseCase {
  final AuthRepository _repository;

  LogoutUserUseCase(this._repository);

  Future<Result<Unit>> call() async {
    return await _repository.logoutUser();
  }
}
