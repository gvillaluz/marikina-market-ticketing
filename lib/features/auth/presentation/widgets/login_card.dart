import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/auth_error_notice.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/router/route_args.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/auth_btn.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/login_card_header.dart';
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
    return Container(
      width: double.infinity,
      decoration: AppTheme.authCardDecoration(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LoginCardHeader(),

          const SizedBox(height: 20),

          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) => LoginFields(
              usernameController: _usernameController,
              passwordController: _passwordController,
              enabled: state is! AuthLoginLoading,
              onSubmitted: _submit,
            ),
          ),

          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) => TextButton(
              onPressed: state is AuthLoginLoading
                  ? null
                  : () => _forgotPassword(context),
              child: const Text('Forgot password?'),
            ),
          ),

          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    AuthBtn(
                      isLoading: state is AuthLoginLoading,
                      onPressed: _submit,
                      label: 'LOGIN',
                    ),

                    const SizedBox(height: 10),

                    if (state
                        case AuthInvalidCredentials(:final message) ||
                            AuthConnectionError(:final message)) ...{
                      AuthErrorNotice(message: message),
                    },
                    if (state is Unauthenticated && state.sessionExpired)
                      const AuthErrorNotice(
                        message:
                            'Your session has expired. Please sign in again.',
                      ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
