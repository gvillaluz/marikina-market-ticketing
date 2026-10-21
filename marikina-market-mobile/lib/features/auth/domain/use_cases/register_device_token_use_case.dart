import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/utils/unit.dart';
import 'package:marikina_market_mobile/features/auth/domain/repositories/auth_repository.dart';

class RegisterDeviceTokenUseCase {
  final AuthRepository _repository;
  RegisterDeviceTokenUseCase(this._repository);

  Future<Result<Unit>> call() async => _repository.registerDeviceToken();
}
