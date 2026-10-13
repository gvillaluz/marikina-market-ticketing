import 'package:marikina_market_mobile/features/password_recovery/domain/entities/verify_code_result.dart';

class VerifyCodeResultModel {
  final bool success;
  final String message;
  final String? resetToken;

  VerifyCodeResultModel({
    required this.success,
    required this.message,
    this.resetToken,
  });

  factory VerifyCodeResultModel.fromJson(Map<String, dynamic> json) {
    return VerifyCodeResultModel(
      success: json['success'] as bool,
      message: json['message'] as String,
      resetToken: json['reset_token'] != null
          ? json['reset_token'] as String
          : null,
    );
  }

  VerifyCodeResult toEntity() {
    return VerifyCodeResult(
      success: success,
      message: message,
      resetToken: resetToken,
    );
  }
}
