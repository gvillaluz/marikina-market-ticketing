import 'package:marikina_market_mobile/features/password_recovery/domain/entities/otp_send_result.dart';

class OtpSendResultModel {
  final String? message;
  final int resendCooldownSeconds;
  final int codeExpirySeconds;

  OtpSendResultModel({
    this.message,
    required this.resendCooldownSeconds,
    required this.codeExpirySeconds,
  });

  factory OtpSendResultModel.fromJson(Map<String, dynamic> json) {
    return OtpSendResultModel(
      message: json['message'] != null ? json['message'] as String : null,
      resendCooldownSeconds: json['resend_cooldown_seconds'] as int,
      codeExpirySeconds: json['code_expiry_seconds'] as int,
    );
  }

  OtpSendResult toEntity() {
    return OtpSendResult(
      message: message,
      resendCooldownSeconds: resendCooldownSeconds,
      codeExpirySeconds: codeExpirySeconds,
    );
  }
}
