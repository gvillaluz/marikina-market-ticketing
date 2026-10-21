import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/entities/reset_password_result.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/find_account_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/reset_password_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/send_otp_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/use_cases/verify_code_use_case.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_event.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_state.dart';

class PasswordRecoveryBloc
    extends Bloc<PasswordRecoveryEvent, PasswordRecoveryState> {
  final FindAccountUseCase findAccountUseCase;
  final SendOtpUseCase sendOtpUseCase;
  final VerifyCodeUseCase verifyOtpUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;

  PasswordRecoveryBloc({
    required this.findAccountUseCase,
    required this.sendOtpUseCase,
    required this.verifyOtpUseCase,
    required this.resetPasswordUseCase,
  }) : super(PasswordInitial()) {
    on<FindAccount>(_onFindAccount);
    on<SendOtp>(_onSendOtp);
    on<VerifyCode>(_onVerifyCode);
    on<ResetPassword>(_onResetPassword);
  }

  bool _busy = false;

  Future<void> _onFindAccount(
    FindAccount event,
    Emitter<PasswordRecoveryState> emit,
  ) async {
    if (_busy) return;
    _busy = true;
    emit(SearchAccountLoading());

    final result = await findAccountUseCase(event.username);

    _busy = false;
    if (emit.isDone) return;
    switch (result) {
      case ResultFailure(failure: final failure):
        emit(SearchAccountFailed(failure.message));
        break;

      case Success(:final data):
        if (data.found) {
          emit(AccountFound(data));
          break;
        }

        emit(SearchAccountFailed('Failed to search account.'));
        break;
    }
  }

  Future<void> _onSendOtp(
    SendOtp event,
    Emitter<PasswordRecoveryState> emit,
  ) async {
    if (_busy) return;
    _busy = true;
    emit(SendOtpLoading());

    final result = await sendOtpUseCase(event.username, event.channel);

    _busy = false;
    if (emit.isDone) return;
    switch (result) {
      case Success(:final data):
        emit(OtpSent(data));
        break;

      case ResultFailure(:final failure):
        emit(SendOtpFailed(failure.message));
    }
  }

  Future<void> _onVerifyCode(
    VerifyCode event,
    Emitter<PasswordRecoveryState> emit,
  ) async {
    if (_busy) return;
    _busy = true;
    emit(VerifyOtpLoading());

    final result = await verifyOtpUseCase(event.username, event.code);

    _busy = false;
    if (emit.isDone) return;
    switch (result) {
      case Success(:final data):
        if (data.success) {
          emit(OtpVerified(data));
        } else {
          emit(OtpVerified(data));
        }
        break;

      case ResultFailure(:final failure):
        emit(VerificationFailed(failure.message));
    }
  }

  Future<void> _onResetPassword(
    ResetPassword event,
    Emitter<PasswordRecoveryState> emit,
  ) async {
    if (_busy) return;
    _busy = true;
    if (event.newPassword != event.confirmNewPassword) {
      emit(
        ResetPasswordSuccessfully(
          ResetPasswordResult(
            success: false,
            message: 'Confirm password must match new password.',
          ),
        ),
      );
    }

    emit(ResetPasswordLoading());

    final result = await resetPasswordUseCase(
      event.username,
      event.newPassword,
      event.resetToken,
    );

    _busy = false;
    if (emit.isDone) return;
    switch (result) {
      case Success(:final data):
        if (data.success) {
          emit(ResetPasswordSuccessfully(data));
        } else {
          emit(ResetPasswordSuccessfully(data));
        }

      case ResultFailure(:final failure):
        emit(ResetPasswordFailed(failure.message));
    }
  }
}
