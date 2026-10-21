import 'package:marikina_market_mobile/features/password_recovery/domain/entities/account_lookup.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/entities/otp_send_result.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/entities/reset_password_result.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/entities/verify_code_result.dart';

abstract class PasswordRecoveryState {}

class PasswordInitial extends PasswordRecoveryState {}

class SearchAccountLoading extends PasswordRecoveryState {}

class AccountFound extends PasswordRecoveryState {
  final AccountLookup accountLookup;
  AccountFound(this.accountLookup);
}

class SearchAccountFailed extends PasswordRecoveryState {
  final String message;
  SearchAccountFailed(this.message);
}

class SendOtpLoading extends PasswordRecoveryState {}

class SendOtpFailed extends PasswordRecoveryState {
  final String message;
  SendOtpFailed(this.message);
}

class OtpSent extends PasswordRecoveryState {
  final OtpSendResult result;
  OtpSent(this.result);
}

class VerifyOtpLoading extends PasswordRecoveryState {}

class OtpVerified extends PasswordRecoveryState {
  final VerifyCodeResult result;
  OtpVerified(this.result);
}

class OtpDenied extends PasswordRecoveryState {
  final VerifyCodeResult result;
  OtpDenied(this.result);
}

class VerificationFailed extends PasswordRecoveryState {
  final String message;
  VerificationFailed(this.message);
}

class ResetPasswordLoading extends PasswordRecoveryState {}

class ResetPasswordSuccessfully extends PasswordRecoveryState {
  final ResetPasswordResult result;

  ResetPasswordSuccessfully(this.result);
}

class ResetPasswordFailed extends PasswordRecoveryState {
  final String message;

  ResetPasswordFailed(this.message);
}
