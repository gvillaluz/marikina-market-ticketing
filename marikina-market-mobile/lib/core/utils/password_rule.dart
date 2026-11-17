class PasswordRule {
  final String label;
  final bool Function(String value) met;

  const PasswordRule(this.label, this.met);
}
