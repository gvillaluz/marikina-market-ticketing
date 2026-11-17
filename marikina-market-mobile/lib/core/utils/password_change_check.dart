import 'package:marikina_market_mobile/core/utils/password_rule.dart';

class PasswordChangeCheck {
  static const hint =
      'At least 8 characters, with a number and a capital letter.';

  static final rules = [
    PasswordRule('At least 8 characters', (value) => value.length >= 8),
    PasswordRule('A number', (value) => value.contains(RegExp(r'[0-9]'))),
    PasswordRule(
      'A capital letter',
      (value) => value.contains(RegExp(r'[A-Z]')),
    ),
  ];

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

  static String? newPasswordProblem(String value) =>
      rules.every((rule) => rule.met(value))
      ? null
      : 'Use at least 8 characters, with a number and a capital letter.';

  String? get newPasswordError => newPasswordProblem(newPassword);

  String? get confirmError {
    if (confirmPassword.isEmpty) return 'Confirm your new password.';
    return confirmPassword == newPassword ? null : 'Passwords do not match.';
  }

  bool get isValid =>
      currentError == null && newPasswordError == null && confirmError == null;
}
