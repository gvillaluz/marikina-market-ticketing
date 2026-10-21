import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/entities/verify_code_result.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/repositories/password_recovery_repository.dart';

class VerifyCodeUseCase {
  final PasswordRecoveryRepository _repository;
  VerifyCodeUseCase(this._repository);

  Future<Result<VerifyCodeResult>> call(String username, String code) async =>
      await _repository.verifyCode(username, code);
}
