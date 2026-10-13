import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/usecases/usecase.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/login_params.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/login_otp_result.dart';
import 'package:marikina_market_mobile/features/auth/domain/repositories/auth_repository.dart';

class LoginUserUseCase implements UseCase<LoginOtpResult, LoginParams> {
  final AuthRepository _repository;
  LoginUserUseCase(this._repository);

  @override
  Future<Result<LoginOtpResult>> call(LoginParams params) async {
    if (params.username.trim().isEmpty || params.password.isEmpty) {
      return Result.failure(
        ValidationFailure('Username and password are required.'),
      );
    }

    return await _repository.loginUser(params.username, params.password);
  }
}
