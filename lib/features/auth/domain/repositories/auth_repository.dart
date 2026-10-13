import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/utils/unit.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/login_otp_result.dart';

abstract class AuthRepository {
  Future<Result<User?>> checkAuth();
  Future<Result<LoginOtpResult>> loginUser(String username, String password);
  Future<Result<User>> verifyLogin(
    String username,
    String password,
    String code,
  );
  Future<Result<Unit>> storeUserInfo(User user);
  Future<Result<User>> mandatoryChangePassword(
    int userId,
    String currentPassword,
    String newPassword,
    String confirmNewPassword,
  );
  Future<Result<Unit>> refreshTokens();
  Future<Result<Unit>> registerDeviceToken();
  Future<Result<Unit>> logoutUser();
  Future<Result<Unit>> syncPendingLogouts();
}
