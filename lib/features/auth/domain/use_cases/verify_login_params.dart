class VerifyLoginParams {
  final String username;
  final String password;
  final String code;
  const VerifyLoginParams({
    required this.username,
    required this.password,
    required this.code,
  });
}
