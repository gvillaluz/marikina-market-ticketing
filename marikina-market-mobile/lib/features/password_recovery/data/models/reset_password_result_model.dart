import 'package:marikina_market_mobile/features/password_recovery/domain/entities/reset_password_result.dart';

class ResetPasswordResultModel {
  final bool success;
  final String message;

  ResetPasswordResultModel({required this.success, required this.message});

  factory ResetPasswordResultModel.fromJson(Map<String, dynamic> json) {
    return ResetPasswordResultModel(
      success: json['success'] as bool,
      message: json['message'] as String,
    );
  }

  ResetPasswordResult toEntity() {
    return ResetPasswordResult(success: success, message: message);
  }
}
