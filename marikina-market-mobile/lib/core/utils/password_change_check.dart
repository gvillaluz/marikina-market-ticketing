class PasswordChangeCheck {
  static const hint =
      'At least 8 characters, with a number and a capital letter.';

  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  const PasswordChangeCheck(
    this.currentPassword,
    this.newPassword,
    this.confirmPassword,
  );

  String? get currentError =>
      currentPassword.isEmpty ? 'Enter your current password.' : null;

  String? get newPasswordError =>
      newPassword.length >= 8 &&
          newPassword.contains(RegExp(r'[0-9]')) &&
          newPassword.contains(RegExp(r'[A-Z]'))
      ? null
      : 'Use at least 8 characters, with a number and a capital letter.';

  String? get confirmError {
    if (confirmPassword.isEmpty) return 'Confirm your new password.';
    return confirmPassword == newPassword ? null : 'Passwords do not match.';
  }

  bool get isValid =>
      currentError == null && newPasswordError == null && confirmError == null;
}
