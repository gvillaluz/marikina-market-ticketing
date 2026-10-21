import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/usecases/usecase.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';
import 'package:marikina_market_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/verify_login_params.dart';

class VerifyLoginUseCase implements UseCase<User, VerifyLoginParams> {
  final AuthRepository _repository;
  VerifyLoginUseCase(this._repository);

  @override
  Future<Result<User>> call(VerifyLoginParams params) {
    if (!RegExp(r'^[0-9]{6}$').hasMatch(params.code)) {
      return Future.value(
        Result.failure(const ValidationFailure('Enter the six-digit code.')),
      );
    }
    return _repository.verifyLogin(
      params.username,
      params.password,
      params.code,
    );
  }
}
