import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/auth_error_notice.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/resend_code_button.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/reveal_message.dart';
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
                isWrong: state.codeRejected,
                isVerified: state.isVerified,
              ),
              RevealMessage(
                child: errorMessage == null
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(
                          top: AppTheme.authSmallGap,
                        ),
                        child: AuthErrorNotice(message: errorMessage),
                      ),
              ),
              const SizedBox(height: AppTheme.authGap),
              AuthBtn(
                label: 'Verify and log in',
                isLoading: state.isVerifying && !state.isVerified,
                isSuccess: state.isVerified,
                onPressed: state.canVerify
                    ? () => context.read<AuthBloc>().add(
                        VerifyLoginSubmitted(
                          _codeController.text,
                          successHold: AppTheme.motionOf(
                            context,
                            AppTheme.authSuccessHold,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: AppTheme.authSmallGap),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppTheme.authSmallGap,
                runSpacing: AppTheme.authSmallGap,
                children: [
                  Text(
                    'Didn’t receive the email?',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.authVerificationBodyColor,
                    ),
                  ),
                  ResendCodeButton(
                    secondsLeft: state.resendCooldownSeconds,
                    isSending: state.isResending,
                    onResend: state.isVerifying
                        ? null
                        : () => context.read<AuthBloc>().add(ResendLoginOtp()),
                  ),
                ],
              ),
              RevealMessage(
                child: isCodeSent
                    ? Padding(
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
                      )
                    : null,
              ),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: state.isVerifying
                      ? null
                      : () => context.read<AuthBloc>().add(CancelLogin()),
                  child: const Text('Back to log in'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
