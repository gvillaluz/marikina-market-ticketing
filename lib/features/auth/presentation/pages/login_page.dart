import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:marikina_market_mobile/features/auth/presentation/widgets/login_card.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppTheme.authPagePadding,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppTheme.authMaxWidth,
                ),
                child: BlocListener<AuthBloc, AuthState>(
                  listener: (context, state) {
                    if (state is Unauthenticated && state.sessionExpired) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Session expired. Please login again.'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    }
                  },
                  child: const LoginCard(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
