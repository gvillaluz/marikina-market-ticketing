abstract class TokenService {
  bool isAccessTokenExpired(String? token);
  Map<String, dynamic>? decodeToken(String? token);
}
