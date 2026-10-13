import 'package:marikina_market_mobile/features/auth/domain/services/token_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class TokenServiceImpl implements TokenService {
  @override
  Map<String, dynamic>? decodeToken(String? token) {
    if (token == null) return null;
    return JwtDecoder.decode(token);
  }

  @override
  bool isAccessTokenExpired(String? token) {
    if (token == null) return true;
    return JwtDecoder.isExpired(token);
  }
}
