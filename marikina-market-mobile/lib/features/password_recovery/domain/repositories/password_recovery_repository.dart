import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/entities/account_lookup.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/entities/otp_send_result.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/entities/reset_password_result.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/entities/verify_code_result.dart';

abstract class PasswordRecoveryRepository {
  Future<Result<AccountLookup>> findAccount(String username);
  Future<Result<OtpSendResult>> sendOtp(String username, String channel);
  Future<Result<VerifyCodeResult>> verifyCode(String username, String code);
  Future<Result<ResetPasswordResult>> resetPassword(
    String username,
    String newPassword,
    String resetToken,
  );
}
