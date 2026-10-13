import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:marikina_market_mobile/features/auth/presentation/widgets/change_password_card.dart';

class MandatoryChangePasswordPage extends StatelessWidget {
  const MandatoryChangePasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: AppTheme.authPagePadding,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppTheme.authMaxWidth,
                ),
                child: BlocListener<AuthBloc, AuthState>(
                  listener: (context, state) {
                    if (state is AuthChangePasswordNetworkError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: AppColors.primaryRed,
                        ),
                      );
                    }

                    if (state is Authenticated) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password successfully changed.'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    }
                  },
                  child: const ChangePasswordCard(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
