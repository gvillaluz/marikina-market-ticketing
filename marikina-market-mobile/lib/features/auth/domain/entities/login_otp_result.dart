class LoginOtpResult {
  final String message;
  final String maskedEmail;
  final int resendCooldownSeconds;
  final int codeExpirySeconds;

  const LoginOtpResult({
    required this.message,
    required this.maskedEmail,
    required this.resendCooldownSeconds,
    required this.codeExpirySeconds,
  });
}
