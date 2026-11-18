import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/auth_error_notice.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/reveal_message.dart';
import 'package:marikina_market_mobile/core/router/route_args.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/auth_btn.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_bloc.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_event.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_state.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/widgets/reset_password_fields.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/widgets/back_to_login_button.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/widgets/recovery_step_counter.dart';

class ResetPasswordPage extends StatefulWidget {
  final ResetPasswordArgs args;
  const ResetPasswordPage({required this.args, super.key});

  @override
  State<StatefulWidget> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmNewPasswordController =
      TextEditingController();

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmNewPasswordController.dispose();
    super.dispose();
  }

  // Waiting for the server, or showing the tick before the next screen.
  static bool _busy(PasswordRecoveryState state) =>
      state is ResetPasswordLoading || _succeeded(state);

  static bool _succeeded(PasswordRecoveryState state) =>
      state is ResetPasswordSuccessfully && state.result.success;

  Future<void> _openLogin(BuildContext context) async {
    await Future<void>.delayed(
      AppTheme.motionOf(context, AppTheme.authSuccessHold),
    );
    if (context.mounted) context.goNamed(Routes.loginName);
  }

  void _submit(BuildContext context) {
    context.read<PasswordRecoveryBloc>().add(
      ResetPassword(
        widget.args.username,
        newPasswordController.text,
        confirmNewPasswordController.text,
        widget.args.resetToken,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PasswordRecoveryBloc, PasswordRecoveryState>(
      listener: (context, state) {
        if (_succeeded(state)) _openLogin(context);
      },
      child: Padding(
        padding: AppTheme.authCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RecoveryStepCounter(step: 4),
            const Text(
              'Create a new password',
              style: AppTheme.authPageTitleStyle,
            ),
            const SizedBox(height: 24),
            ResetPasswordFields(
              enabled: context.select<PasswordRecoveryBloc, bool>(
                (bloc) => !_busy(bloc.state),
              ),
              newPasswordController: newPasswordController,
              confirmNewPasswordController: confirmNewPasswordController,
            ),
            const SizedBox(height: 20),
            BlocBuilder<PasswordRecoveryBloc, PasswordRecoveryState>(
              builder: (context, state) {
                final error = switch (state) {
                  ResetPasswordFailed(:final message) => message,
                  _ => null,
                };
                return Column(
                  children: [
                    AuthBtn(
                      onPressed: () => _submit(context),
                      isLoading: state is ResetPasswordLoading,
                      isSuccess: _succeeded(state),
                      label: 'Change Password',
                    ),
                    RevealMessage(
                      child: error == null
                          ? null
                          : Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: AuthErrorNotice(message: error),
                            ),
                    ),
                    BackToLoginButton(enabled: !_busy(state)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
