import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';

abstract class AuthEvent {}

class CheckAuthStatus extends AuthEvent {}

class LoginSubmitted extends AuthEvent {
  final String username;
  final String password;
  final Duration successHold;

  LoginSubmitted({
    required this.username,
    required this.password,
    this.successHold = Duration.zero,
  });
}

class UserUpdated extends AuthEvent {
  final User user;
  UserUpdated(this.user);
}

class ChangePasswordSubmitted extends AuthEvent {
  final int userId;
  final String currentPassword;
  final String newPassword;
  final String confirmNewPassword;
  final Duration successHold;

  ChangePasswordSubmitted({
    required this.userId,
    required this.currentPassword,
    required this.newPassword,
    required this.confirmNewPassword,
    this.successHold = Duration.zero,
  });
}

class RefreshTokens extends AuthEvent {}

class RegisterDeviceTokenRequested extends AuthEvent {}

class LogoutUser extends AuthEvent {
  final bool sessionExpired;
  LogoutUser(this.sessionExpired);
}

class VerifyLoginSubmitted extends AuthEvent {
  final String code;
  final Duration successHold;
  VerifyLoginSubmitted(this.code, {this.successHold = Duration.zero});
}

class ResendLoginOtp extends AuthEvent {}

class CancelLogin extends AuthEvent {}

class LoginOtpCountdownUpdated extends AuthEvent {}
