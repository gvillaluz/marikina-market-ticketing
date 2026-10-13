class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final DateTime refreshTokenExpiration;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.refreshTokenExpiration,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      refreshTokenExpiration: DateTime.parse(
        json['refresh_token_expiration'] as String,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'refresh_token_expiration': refreshTokenExpiration.toIso8601String(),
    };
  }
}
