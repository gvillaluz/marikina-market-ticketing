import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/connectivity/connectivity_status.dart';
import 'package:marikina_market_mobile/core/connectivity/cubit/connectivity_cubit.dart';
import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/check_auth_status_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/login_user_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/login_otp_result.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/login_params.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/verify_login_params.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/verify_login_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/logout_user_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/mandatory_change_password_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/refresh_tokens_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/register_device_token_use_case.dart';
import 'package:marikina_market_mobile/features/auth/domain/use_cases/sync_pending_logouts_use_case.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/sync_pending_logouts.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ConnectivityCubit connectivityCubit;
  final CheckAuthStatusUseCase checkAuthStatusUseCase;
  final LoginUserUseCase loginUserUseCase;
  final VerifyLoginUseCase verifyLoginUseCase;
  final LogoutUserUseCase logoutUserUseCase;
  final MandatoryChangePasswordUseCase mandatoryChangePasswordUseCase;
  final RefreshTokensUseCase refreshTokensUseCase;
  final RegisterDeviceTokenUseCase registerDeviceTokenUseCase;
  final SyncPendingLogoutsUseCase syncPendingLogoutsUseCase;

  String? _loginUsername;
  String? _loginPassword;
  String _maskedEmail = '';
  DateTime? _resendAvailableAt;
  DateTime? _codeExpiresAt;
  Timer? _otpTimer;
  int _loginGeneration = 0;
  bool _loginBusy = false;
  bool _loggingOut = false;

  late final StreamSubscription<ConnectivityStatus> _connectivitySubscription;
  Timer? _tokenCheckTimer;

  AuthBloc({
    required this.connectivityCubit,
    required this.checkAuthStatusUseCase,
    required this.loginUserUseCase,
    required this.verifyLoginUseCase,
    required this.logoutUserUseCase,
    required this.mandatoryChangePasswordUseCase,
    required this.refreshTokensUseCase,
    required this.registerDeviceTokenUseCase,
    required this.syncPendingLogoutsUseCase,
  }) : super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<VerifyLoginSubmitted>(_onVerifyLoginSubmitted);
    on<ResendLoginOtp>(_onResendLoginOtp);
    on<CancelLogin>((event, emit) {
      if (state case LoginOtpPending(isVerifying: true)) return;
      _clearPendingLogin();
      emit(Unauthenticated(false));
    });
    on<LoginOtpCountdownUpdated>((event, emit) {
      final pending = state;
      if (pending is LoginOtpPending) {
        emit(
          _pendingState(
            message: pending.message,
            isVerifying: pending.isVerifying,
            isResending: pending.isResending,
            requiresNewCode: pending.requiresNewCode,
          ),
        );
      }
    });
    on<LogoutUser>(_onLogoutUser);
    on<UserUpdated>(_onUserUpdated);
    on<ChangePasswordSubmitted>(_onChangePasswordSubmitted);
    on<RefreshTokens>(_onRefreshTokens);
    on<SyncPendingLogouts>(_onSyncPendingLogouts);

    _connectivitySubscription = connectivityCubit.stream.listen((status) {
      if (status == ConnectivityStatus.online) {
        add(SyncPendingLogouts());
        add(RefreshTokens());
      }
    });

    _tokenCheckTimer = Timer.periodic(const Duration(minutes: 14), (_) {
      if (connectivityCubit.state == ConnectivityStatus.online) {
        add(RefreshTokens());
        add(SyncPendingLogouts());
      }
    });

    add(SyncPendingLogouts());
    add(CheckAuthStatus());
  }

  @override
  Future<void> close() {
    _clearPendingLogin();
    _connectivitySubscription.cancel();
    _tokenCheckTimer?.cancel();
    return super.close();
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await checkAuthStatusUseCase();
    if (state is! AuthLoading) return;

    switch (result) {
      case ResultFailure():
        emit(Unauthenticated(false));

      case Success(data: final user):
        if (user != null) {
          emit(Authenticated(user: user));
        } else {
          emit(Unauthenticated(false));
        }
    }
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    if (_loginBusy || state is Authenticated || state is LoginOtpPending) {
      return;
    }
    _clearPendingLogin();
    final generation = _loginGeneration;
    _loginBusy = true;
    emit(AuthLoginLoading());
    final username = event.username.trim();
    final result = await loginUserUseCase(
      LoginParams(username: username, password: event.password),
    );
    if (generation != _loginGeneration || emit.isDone) return;
    _loginBusy = false;
    switch (result) {
      case ResultFailure(failure: final failure):
        emit(AuthInvalidCredentials(failure.message));
      case Success(data: final otp):
        _loginUsername = username;
        _loginPassword = event.password;
        _applyOtpResult(otp);
        emit(_pendingState());
    }
  }

  Future<void> _onResendLoginOtp(
    ResendLoginOtp event,
    Emitter<AuthState> emit,
  ) async {
    final pending = state;
    if (pending is! LoginOtpPending ||
        !pending.canResend ||
        _loginBusy ||
        _secondsUntil(_resendAvailableAt) > 0) {
      return;
    }
    final username = _loginUsername;
    final password = _loginPassword;
    if (username == null || password == null) return;
    final generation = _loginGeneration;
    _loginBusy = true;
    emit(
      _pendingState(
        isResending: true,
        requiresNewCode: pending.requiresNewCode,
      ),
    );
    final result = await loginUserUseCase(
      LoginParams(username: username, password: password),
    );
    if (generation != _loginGeneration || emit.isDone) return;
    _loginBusy = false;
    switch (result) {
      case ResultFailure(failure: final failure):
        emit(
          _pendingState(
            message: failure.message,
            requiresNewCode: pending.requiresNewCode,
          ),
        );
      case Success(data: final otp):
        _applyOtpResult(otp);
        emit(_pendingState(message: otp.message));
    }
  }

  Future<void> _onVerifyLoginSubmitted(
    VerifyLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final pending = state;
    if (pending is! LoginOtpPending || !pending.canVerify || _loginBusy) return;
    if (_secondsUntil(_codeExpiresAt) == 0) {
      emit(_pendingState(message: 'Code expired. Request a new one.'));
      return;
    }
    final username = _loginUsername;
    final password = _loginPassword;
    if (username == null || password == null) return;
    final generation = _loginGeneration;
    _loginBusy = true;
    emit(_pendingState(isVerifying: true));
    final result = await verifyLoginUseCase(
      VerifyLoginParams(
        username: username,
        password: password,
        code: event.code,
      ),
    );
    if (generation != _loginGeneration || emit.isDone) return;
    _loginBusy = false;
    switch (result) {
      case ResultFailure(failure: final failure):
        final requiresNewCode =
            failure.message == 'Too many attempts. Request a new code.' ||
            failure.message == 'Code expired. Request a new one.' ||
            failure.message.startsWith('Invalid or expired code');
        emit(
          _pendingState(
            message: failure.message,
            requiresNewCode: requiresNewCode,
          ),
        );
      case Success(data: final user):
        _clearPendingLogin();
        emit(Authenticated(user: user));
        unawaited(registerDeviceTokenUseCase());
    }
  }

  void _applyOtpResult(LoginOtpResult otp) {
    final now = DateTime.now();
    _maskedEmail = otp.maskedEmail;
    _resendAvailableAt = now.add(Duration(seconds: otp.resendCooldownSeconds));
    _codeExpiresAt = now.add(Duration(seconds: otp.codeExpirySeconds));
    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isClosed) add(LoginOtpCountdownUpdated());
    });
  }

  int _secondsUntil(DateTime? deadline) {
    if (deadline == null) return 0;
    final milliseconds = deadline.difference(DateTime.now()).inMilliseconds;
    return milliseconds <= 0 ? 0 : (milliseconds / 1000).ceil();
  }

  LoginOtpPending _pendingState({
    String? message,
    bool isVerifying = false,
    bool isResending = false,
    bool requiresNewCode = false,
  }) => LoginOtpPending(
    maskedEmail: _maskedEmail,
    resendCooldownSeconds: _secondsUntil(_resendAvailableAt),
    codeExpirySeconds: _secondsUntil(_codeExpiresAt),
    message: message,
    isVerifying: isVerifying,
    isResending: isResending,
    requiresNewCode: requiresNewCode,
  );

  void _clearPendingLogin() {
    _loginGeneration++;
    _loginBusy = false;
    _loginUsername = null;
    _loginPassword = null;
    _maskedEmail = '';
    _resendAvailableAt = null;
    _codeExpiresAt = null;
    _otpTimer?.cancel();
    _otpTimer = null;
  }

  Future<void> _onChangePasswordSubmitted(
    ChangePasswordSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    if (_loggingOut || state is AuthChangePasswordLoading) return;
    emit(AuthChangePasswordLoading());

    final result = await mandatoryChangePasswordUseCase(
      MandatoryChangePasswordParams(
        userId: event.userId,
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
        confirmNewPassword: event.confirmNewPassword,
      ),
    );

    if (emit.isDone) return;
    switch (result) {
      case Success(data: final user):
        emit(Authenticated(user: user));
      case ResultFailure(failure: UnauthorizedFailure()):
        emit(Unauthenticated(false));
      case ResultFailure(
        failure: NetworkFailure(:final message) ||
            ServerFailure(:final message),
      ):
        emit(
          AuthChangePasswordNetworkError(
            message.trim().isEmpty
                ? 'Unable to update your password. Please try again.'
                : message,
          ),
        );
      case ResultFailure(failure: final failure):
        emit(
          AuthChangePasswordError(
            failure.message.trim().isEmpty
                ? 'Unable to update your password. Please try again.'
                : failure.message,
          ),
        );
    }
  }

  Future<void> _onLogoutUser(LogoutUser event, Emitter<AuthState> emit) async {
    if (_loggingOut) return;
    _loggingOut = true;
    try {
      _clearPendingLogin();
      final logoutResult = await logoutUserUseCase();
      if (emit.isDone) return;
      switch (logoutResult) {
        case ResultFailure(failure: final failure):
          emit(
            AuthConnectionError(
              failure.message.trim().isEmpty
                  ? 'Unable to confirm logout. Please try again.'
                  : failure.message,
            ),
          );
        case Success():
          emit(Unauthenticated(event.sessionExpired));
      }
    } finally {
      _loggingOut = false;
    }
  }

  Future<void> _onSyncPendingLogouts(
    SyncPendingLogouts event,
    Emitter<AuthState> emit,
  ) async {
    final result = await syncPendingLogoutsUseCase();
    if (emit.isDone) return;
    if (result is Success && state is Authenticated) {
      await registerDeviceTokenUseCase();
    } else if (result case ResultFailure(
      failure: ValidationFailure(:final message),
    )) {
      if (state is Unauthenticated) {
        emit(
          AuthConnectionError(
            message.trim().isEmpty
                ? 'A pending logout request was rejected. Please sign in again.'
                : message,
          ),
        );
      }
    }
  }

  Future<void> _onUserUpdated(
    UserUpdated event,
    Emitter<AuthState> emit,
  ) async => emit(Authenticated(user: event.user));

  Future<void> _onRefreshTokens(
    RefreshTokens event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! Authenticated || _loggingOut) return;

    final result = await refreshTokensUseCase();
    if (emit.isDone || _loggingOut || state is! Authenticated) return;

    switch (result) {
      case Success():
        break;

      case ResultFailure():
        emit(Unauthenticated(false));
    }
  }
}
