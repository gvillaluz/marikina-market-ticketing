class VerifyCodeResult {
  final bool success;
  final String message;
  final String? resetToken;

  VerifyCodeResult({
    required this.success,
    required this.message,
    this.resetToken,
  });
}
