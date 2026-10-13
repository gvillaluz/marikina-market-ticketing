class Token {
  final String accessToken;
  final String refreshToken;
  final DateTime refreshTokenExpiration;

  const Token({
    required this.accessToken,
    required this.refreshToken,
    required this.refreshTokenExpiration,
  });
}
