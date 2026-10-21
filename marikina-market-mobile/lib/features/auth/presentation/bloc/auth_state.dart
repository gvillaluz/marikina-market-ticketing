import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  Authenticated({required this.user});
}

class AuthLoggingOut extends Authenticated {
  AuthLoggingOut({required super.user});
}

class AuthLoginLoading extends AuthState {}

class Unauthenticated extends AuthState {
  final bool sessionExpired;
  Unauthenticated(this.sessionExpired);
}

class AuthInvalidCredentials extends AuthState {
  final String message;
  AuthInvalidCredentials(this.message);
}

class AuthConnectionError extends AuthState {
  final String message;
  AuthConnectionError(this.message);
}

class AuthLogoutSuccess extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError({required this.message});
}

class AuthChangePasswordLoading extends AuthState {}

class AuthChangePasswordError extends AuthState {
  final String message;
  AuthChangePasswordError(this.message);
}

class AuthChangePasswordNetworkError extends AuthState {
  final String message;
  AuthChangePasswordNetworkError(this.message);
}

class LoginOtpPending extends AuthState {
  final String maskedEmail;
  final int resendCooldownSeconds;
  final int codeExpirySeconds;
  final String? message;
  final bool isVerifying;
  final bool isResending;
  final bool requiresNewCode;

  LoginOtpPending({
    required this.maskedEmail,
    required this.resendCooldownSeconds,
    required this.codeExpirySeconds,
    this.message,
    this.isVerifying = false,
    this.isResending = false,
    this.requiresNewCode = false,
  });

  bool get isBusy => isVerifying || isResending;
  bool get canVerify => !isBusy && !requiresNewCode && codeExpirySeconds > 0;
  bool get canResend => !isBusy && resendCooldownSeconds == 0;
}
