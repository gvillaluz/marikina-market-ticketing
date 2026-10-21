import 'package:marikina_market_mobile/features/auth/domain/entities/login_otp_result.dart';

class LoginOtpResultModel {
  final String message;
  final String maskedEmail;
  final int resendCooldownSeconds;
  final int codeExpirySeconds;

  const LoginOtpResultModel({
    required this.message,
    required this.maskedEmail,
    required this.resendCooldownSeconds,
    required this.codeExpirySeconds,
  });

  factory LoginOtpResultModel.fromJson(Map<String, Object?> json) {
    final message = json['message'];
    final email = json['masked_email'];
    final cooldown = json['resend_cooldown_seconds'];
    final expiry = json['code_expiry_seconds'];
    if (message is! String ||
        email is! String ||
        email.isEmpty ||
        cooldown is! int ||
        cooldown < 0 ||
        expiry is! int ||
        expiry < 0) {
      throw const FormatException('Invalid login code response.');
    }
    return LoginOtpResultModel(
      message: message,
      maskedEmail: email,
      resendCooldownSeconds: cooldown,
      codeExpirySeconds: expiry,
    );
  }

  LoginOtpResult toEntity() => LoginOtpResult(
    message: message,
    maskedEmail: maskedEmail,
    resendCooldownSeconds: resendCooldownSeconds,
    codeExpirySeconds: codeExpirySeconds,
  );
}
