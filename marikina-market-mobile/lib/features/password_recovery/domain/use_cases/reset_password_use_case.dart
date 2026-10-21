import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/entities/reset_password_result.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/repositories/password_recovery_repository.dart';

class ResetPasswordUseCase {
  final PasswordRecoveryRepository _repository;
  ResetPasswordUseCase(this._repository);

  Future<Result<ResetPasswordResult>> call(
    String username,
    String newPassword,
    String resetToken,
  ) async => await _repository.resetPassword(username, newPassword, resetToken);
}
