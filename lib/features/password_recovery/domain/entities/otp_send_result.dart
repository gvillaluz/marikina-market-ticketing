class OtpSendResult {
  final String? message;
  final int resendCooldownSeconds;
  final int codeExpirySeconds;

  OtpSendResult({
    this.message,
    required this.resendCooldownSeconds,
    required this.codeExpirySeconds,
  });
}
