class LogoutRequest {
  final String deviceToken;
  final String? refreshToken;

  const LogoutRequest({required this.deviceToken, this.refreshToken});
}
