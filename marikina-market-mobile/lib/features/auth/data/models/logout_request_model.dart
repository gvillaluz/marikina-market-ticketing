import 'package:marikina_market_mobile/features/auth/domain/entities/logout_request.dart';

class LogoutRequestModel {
  final String deviceToken;
  final String? refreshToken;

  const LogoutRequestModel({required this.deviceToken, this.refreshToken});

  factory LogoutRequestModel.fromJson(Map<String, Object?> json) =>
      LogoutRequestModel(
        deviceToken: json['device_token'] as String,
        refreshToken: json['refresh_token'] as String?,
      );

  Map<String, Object?> toJson() => {
    'device_token': deviceToken,
    if (refreshToken != null) 'refresh_token': refreshToken,
  };

  LogoutRequest toEntity() =>
      LogoutRequest(deviceToken: deviceToken, refreshToken: refreshToken);
}
