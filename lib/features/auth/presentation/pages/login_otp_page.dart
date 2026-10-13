import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:marikina_market_mobile/features/auth/presentation/widgets/login_otp_card.dart';

class LoginOtpPage extends StatelessWidget {
  const LoginOtpPage({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<AuthBloc, AuthState>(
    builder: (context, state) => PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && state is LoginOtpPending && !state.isVerifying) {
          context.read<AuthBloc>().add(CancelLogin());
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: AppTheme.authPagePadding,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppTheme.authMaxWidth,
                ),
                child: state is LoginOtpPending
                    ? LoginOtpCard(state: state)
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
