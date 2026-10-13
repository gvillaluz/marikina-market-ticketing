import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/login_card_header.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/auth_btn.dart';
import 'package:marikina_market_mobile/features/auth/presentation/widgets/login_otp_field.dart';
import 'package:marikina_market_mobile/features/auth/presentation/widgets/login_otp_heading.dart';

class LoginOtpCard extends StatefulWidget {
  final LoginOtpPending state;
  const LoginOtpCard({super.key, required this.state});

  @override
  State<LoginOtpCard> createState() => _LoginOtpCardState();
}

class _LoginOtpCardState extends State<LoginOtpCard> {
  final _codeController = TextEditingController();

  @override
  void didUpdateWidget(covariant LoginOtpCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.isResending &&
        !widget.state.isResending &&
        (widget.state.message == 'Code sent.' ||
            widget.state.message == 'Code already sent.')) {
      _codeController.clear();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String _countdown(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final theme = Theme.of(context);
    final isCodeSent =
        state.message == 'Code sent.' || state.message == 'Code already sent.';
    final errorMessage =
        !isCodeSent && state.message != null && state.message!.trim().isNotEmpty
        ? state.message
        : state.codeExpirySeconds == 0
        ? 'This code has expired. Request a new code below.'
        : null;
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
                LoginOtpHeading(maskedEmail: state.maskedEmail),
                const SizedBox(height: AppTheme.authGap),
                LoginOtpField(
                  controller: _codeController,
                  enabled: state.canVerify,
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: AppTheme.authSmallGap),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      errorMessage,
                      textAlign: TextAlign.start,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.authGap),
                AuthBtn(
                  label: 'Verify & sign in',
                  isLoading: state.isVerifying,
                  onPressed: state.canVerify
                      ? () => context.read<AuthBloc>().add(
                          VerifyLoginSubmitted(_codeController.text),
                        )
                      : null,
                ),
                const SizedBox(height: AppTheme.authSmallGap),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Didn’t receive the email?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.authVerificationBodyColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.authSmallGap),
                    TextButton(
                      onPressed: state.canResend
                          ? () => context.read<AuthBloc>().add(ResendLoginOtp())
                          : null,
                      child: Text(
                        state.isResending
                            ? 'Sending code...'
                            : state.resendCooldownSeconds > 0
                            ? 'Resend in ${_countdown(state.resendCooldownSeconds)}'
                            : 'Resend code',
                      ),
                    ),
                  ],
                ),
                if (isCodeSent)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.authSmallGap,
                    ),
                    child: Text(
                      state.message!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: state.isVerifying
                        ? null
                        : () => context.read<AuthBloc>().add(CancelLogin()),
                    child: const Text('Back to login'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
