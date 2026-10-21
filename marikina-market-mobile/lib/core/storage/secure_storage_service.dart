abstract class SecureStorageService {
  Future<void> saveAccessToken(String token);
  Future<String?> getAccessToken();

  Future<void> saveRefreshToken(String token);
  Future<String?> getRefreshToken();

  Future<void> saveRefreshTokenExpiration(String expiration);
  Future<String?> getRefreshTokenExpiration();

  Future<void> saveTokens(
    String accessToken,
    String refreshToken,
    String refreshTokenExpiration,
  );

  Future<void> saveUser(String user);

  Future<String?> getUser();

  Future<void> deleteUserAndToken();
  Future<String?> getDeviceToken();
  Future<void> saveDeviceToken(String token);
  Future<String?> getPendingLogouts();
  Future<void> savePendingLogouts(String requests);
  Future<void> deletePendingLogouts();
}
