import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/auth_error_notice.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/reveal_message.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/router/route_args.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/auth_btn.dart';
import 'package:marikina_market_mobile/features/auth/presentation/widgets/login_fields.dart';

class LoginCard extends StatefulWidget {
  const LoginCard({super.key});

  @override
  State<StatefulWidget> createState() => _LoginCardState();
}

class _LoginCardState extends State<LoginCard> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (context.read<AuthBloc>().state is AuthLoginLoading) return;
    context.read<AuthBloc>().add(
      LoginSubmitted(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        successHold: AppTheme.motionOf(context, AppTheme.authSuccessHold),
      ),
    );
  }

  void _forgotPassword(BuildContext context) {
    if (_usernameController.text.isNotEmpty) {
      context.pushNamed(
        Routes.forgotPasswordOptionName,
        extra: ForgotPasswordOptionArgs(
          username: _usernameController.text.trim(),
        ),
      );
    } else {
      context.push(Routes.findAccount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppTheme.authCardPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Log in', style: AppTheme.authPageTitleStyle),
          const SizedBox(height: 4),
          const Text(
            'Use your staff username and password.',
            style: AppTheme.authSubtitleStyle,
          ),
          const SizedBox(height: AppTheme.authGap),

          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) => LoginFields(
              usernameController: _usernameController,
              passwordController: _passwordController,
              enabled: state is! AuthLoginLoading,
              onSubmitted: _submit,
              onForgotPassword: state is AuthLoginLoading
                  ? null
                  : () => _forgotPassword(context),
            ),
          ),

          const SizedBox(height: AppTheme.authGap),

          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthBtn(
                    isLoading: state is AuthLoginLoading && !state.succeeded,
                    isSuccess: state is AuthLoginLoading && state.succeeded,
                    onPressed: _submit,
                    label: 'Log in',
                  ),

                  const SizedBox(height: AppTheme.authSmallGap),

                  const Text(
                    'Next, we email you a 6-digit code to finish logging in.',
                    style: AppTheme.authSubtitleStyle,
                  ),

                  const SizedBox(height: 10),

                  RevealMessage(
                    child: switch (state) {
                      AuthInvalidCredentials(:final message) ||
                      AuthConnectionError(
                        :final message,
                      ) => AuthErrorNotice(message: message),
                      Unauthenticated(sessionExpired: true) =>
                        const AuthErrorNotice(
                          message:
                              'Your session has expired. Please log in again.',
                        ),
                      _ => null,
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
