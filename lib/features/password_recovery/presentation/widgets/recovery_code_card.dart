import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/router/route_args.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/auth_btn.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/otp_code_field.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/login_card_header.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_bloc.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_event.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_state.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/widgets/resend_text.dart';

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

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<PasswordRecoveryBloc, PasswordRecoveryState>(
    listener: (context, state) {
      if (state is OtpSent) {
        _code.clear();
        _countdown(state.result.resendCooldownSeconds);
      }
      if (state is OtpVerified && state.result.success) {
        final token = state.result.resetToken;
        if (token != null && token.trim().isNotEmpty) {
          context.goNamed(
            Routes.resetPasswordName,
            extra: ResetPasswordArgs(
              username: widget.args.username,
              resetToken: token,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Verification could not be completed. Please try again.',
              ),
            ),
          );
        }
      }
    },
    builder: (context, state) {
      final busy = state is SendOtpLoading || state is VerifyOtpLoading;
      final String? error = switch (state) {
        SendOtpFailed(:final message) ||
        VerificationFailed(:final message) => message,
        OtpVerified(:final result) when !result.success => result.message,
        _ => null,
      };
      final channelValue = widget.args.channel == 'email'
          ? widget.args.account.maskedEmail
          : widget.args.account.masketPhoneNumber;
      return Container(
        width: double.infinity,
        decoration: AppTheme.authCardDecoration(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LoginCardHeader(),
            Padding(
              padding: AppTheme.authCardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Check your ${widget.args.channel}',
                    style: AppTheme.authHeadingStyle,
                  ),
                  const SizedBox(height: AppTheme.authSmallGap),
                  Text(
                    'Enter the 6-digit verification code sent to $channelValue.',
                    style: AppTheme.authBodyStyle,
                  ),
                  const SizedBox(height: AppTheme.authGap),
                  OtpCodeField(controller: _code, enabled: !busy),
                  const SizedBox(height: AppTheme.authGap),
                  ValueListenableBuilder<int>(
                    valueListenable: _remaining,
                    builder: (context, seconds, child) => ResendText(
                      cooldownSeconds: seconds,
                      isSending: busy,
                      onResend: () => context.read<PasswordRecoveryBloc>().add(
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
                    onPressed: busy
                        ? null
                        : () => context.read<PasswordRecoveryBloc>().add(
                            VerifyCode(widget.args.username, _code.text.trim()),
                          ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: AppTheme.authSmallGap),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        error.trim().isEmpty
                            ? 'Please try again to verify your code.'
                            : error,
                        textAlign: TextAlign.center,
                        style: AppTheme.authBodyStyle.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => context.goNamed(Routes.loginName),
                    child: const Text('Back to login'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
