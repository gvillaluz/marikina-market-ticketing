import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/entities/otp_send_result.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/repositories/password_recovery_repository.dart';

class SendOtpUseCase {
  final PasswordRecoveryRepository _repository;
  SendOtpUseCase(this._repository);

  Future<Result<OtpSendResult>> call(String username, String channel) async =>
      _repository.sendOtp(username, channel);
}
