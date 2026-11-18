import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/router/route_args.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/auth_btn.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/otp_code_field.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/auth_error_notice.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/reveal_message.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_bloc.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_event.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_state.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/widgets/resend_text.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/widgets/back_to_login_button.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/widgets/recovery_step_counter.dart';

class RecoveryCodeCard extends StatefulWidget {
  final CodeValidationArgs args;
  const RecoveryCodeCard({required this.args, super.key});
  @override
  State<RecoveryCodeCard> createState() => _RecoveryCodeCardState();
}

class _RecoveryCodeCardState extends State<RecoveryCodeCard> {
  final _code = TextEditingController();
  final _remaining = ValueNotifier<int>(0);
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    context.read<PasswordRecoveryBloc>().add(
      SendOtp(username: widget.args.username, channel: widget.args.channel),
    );
  }

  void _countdown(int seconds) {
    _timer?.cancel();
    _remaining.value = seconds;
    if (seconds <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining.value <= 1) {
        _remaining.value = 0;
        timer.cancel();
      } else {
        _remaining.value--;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _remaining.dispose();
    _code.dispose();
    super.dispose();
  }

  // The server accepted the code and gave a reset token.
  static String? _resetToken(PasswordRecoveryState state) {
    if (state is! OtpVerified || !state.result.success) return null;
    final token = state.result.resetToken;
    return token == null || token.trim().isEmpty ? null : token;
  }

  Future<void> _openResetPassword(BuildContext context, String token) async {
    await Future<void>.delayed(
      AppTheme.motionOf(context, AppTheme.authSuccessHold),
    );
    if (!context.mounted) return;
    context.goNamed(
      Routes.resetPasswordName,
      extra: ResetPasswordArgs(
        username: widget.args.username,
        resetToken: token,
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<PasswordRecoveryBloc, PasswordRecoveryState>(
    listener: (context, state) {
      if (state is OtpSent) {
        _code.clear();
        _countdown(state.result.resendCooldownSeconds);
      }
      final token = _resetToken(state);
      if (token != null) _openResetPassword(context, token);
    },
    builder: (context, state) {
      final verified = _resetToken(state) != null;
      final busy =
          state is SendOtpLoading || state is VerifyOtpLoading || verified;
      final String? error = switch (state) {
        SendOtpFailed(:final message) ||
        VerificationFailed(:final message) => message,
        OtpVerified(:final result) when !result.success => result.message,
        OtpVerified(:final result)
            when result.resetToken == null ||
                result.resetToken!.trim().isEmpty =>
          'Verification could not be completed. Please try again.',
        _ => null,
      };
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: AppTheme.authCardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const RecoveryStepCounter(step: 3),
                Text(
                  'Check your ${widget.args.channel}',
                  style: AppTheme.authPageTitleStyle,
                ),
                const SizedBox(height: AppTheme.authSmallGap),
                Text(
                  'Enter the 6-digit verification code sent to ${widget.args.account.maskedEmail}.',
                  style: AppTheme.authBodyStyle.copyWith(
                    color: AppTheme.authVerificationBodyColor,
                  ),
                ),
                const SizedBox(height: AppTheme.authGap),
                OtpCodeField(
                  controller: _code,
                  enabled: !busy,
                  isWrong: state is OtpVerified && !state.result.success,
                  isVerified: verified,
                ),
                const SizedBox(height: AppTheme.authGap),
                ValueListenableBuilder<int>(
                  valueListenable: _remaining,
                  builder: (context, seconds, child) => ResendText(
                    cooldownSeconds: seconds,
                    isSending: busy && !verified,
                    onResend: verified
                        ? null
                        : () => context.read<PasswordRecoveryBloc>().add(
                            SendOtp(
                              username: widget.args.username,
                              channel: widget.args.channel,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: AppTheme.authGap),
                AuthBtn(
                  label: 'Verify',
                  isLoading: state is VerifyOtpLoading,
                  isSuccess: verified,
                  onPressed: busy
                      ? null
                      : () => context.read<PasswordRecoveryBloc>().add(
                          VerifyCode(widget.args.username, _code.text.trim()),
                        ),
                ),
                RevealMessage(
                  child: error == null
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(
                            top: AppTheme.authSmallGap,
                          ),
                          child: AuthErrorNotice(
                            message: error.trim().isEmpty
                                ? 'Please try again to verify your code.'
                                : error,
                          ),
                        ),
                ),
                BackToLoginButton(enabled: !busy),
              ],
            ),
          ),
        ],
      );
    },
  );
}
