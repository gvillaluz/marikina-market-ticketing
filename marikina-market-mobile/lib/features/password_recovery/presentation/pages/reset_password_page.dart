import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/auth_error_notice.dart';
import 'package:marikina_market_mobile/core/router/route_args.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/login_card_header.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/auth_btn.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_bloc.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_event.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_state.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/widgets/reset_password_fields.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/widgets/back_to_login_button.dart';

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

  void _submit(BuildContext context) {
    context.read<PasswordRecoveryBloc>().add(
      ResetPassword(
        widget.args.username,
        newPasswordController.text.trim(),
        confirmNewPasswordController.text.trim(),
        widget.args.resetToken,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: AppTheme.authPagePadding,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppTheme.authMaxWidth,
                ),
                child: BlocListener<PasswordRecoveryBloc, PasswordRecoveryState>(
                  listener: (context, state) {
                    if (state is ResetPasswordSuccessfully &&
                        state.result.success) {
                      context.goNamed(Routes.loginName);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: AppTheme.authCardDecoration(context),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const LoginCardHeader(),
                        Padding(
                          padding: AppTheme.authCardPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Create a new password',
                                style: AppTheme.authPageTitleStyle,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Use at least 8 characters with a combination of letters and numbers.',
                                style: TextStyle(
                                  color: AppTheme.authVerificationBodyColor,
                                  fontSize: AppTheme.bodyFontSize,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ResetPasswordFields(
                                enabled: context
                                    .select<PasswordRecoveryBloc, bool>(
                                      (bloc) =>
                                          bloc.state is! ResetPasswordLoading,
                                    ),
                                newPasswordController: newPasswordController,
                                confirmNewPasswordController:
                                    confirmNewPasswordController,
                              ),
                              const SizedBox(height: 20),
                              BlocBuilder<
                                PasswordRecoveryBloc,
                                PasswordRecoveryState
                              >(
                                builder: (context, state) {
                                  final error = switch (state) {
                                    ResetPasswordFailed(:final message) =>
                                      message,
                                    ResetPasswordSuccessfully(:final result)
                                        when !result.success =>
                                      result.message,
                                    _ => null,
                                  };
                                  return Column(
                                    children: [
                                      AuthBtn(
                                        onPressed: () => _submit(context),
                                        isLoading:
                                            state is ResetPasswordLoading,
                                        label: 'Change Password',
                                      ),
                                      if (error != null) ...[
                                        const SizedBox(height: 12),
                                        AuthErrorNotice(message: error),
                                      ],
                                      BackToLoginButton(
                                        enabled: state is! ResetPasswordLoading,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
