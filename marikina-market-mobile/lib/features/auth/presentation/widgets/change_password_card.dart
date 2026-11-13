import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/utils/password_change_check.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/auth_error_notice.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:marikina_market_mobile/features/auth/presentation/widgets/change_password_fields.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/auth_btn.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/login_card_header.dart';

class ChangePasswordCard extends StatefulWidget {
  const ChangePasswordCard({super.key});

  @override
  State<StatefulWidget> createState() => _ChangePasswordCardState();
}

class _ChangePasswordCardState extends State<ChangePasswordCard> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController =
      TextEditingController();
  PasswordChangeCheck? _check;
  int userId = 0;

  @override
  void initState() {
    super.initState();

    var authState = context.read<AuthBloc>().state;

    if (authState is Authenticated) {
      userId = authState.user.userId;
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    final check = PasswordChangeCheck(
      _currentPasswordController.text,
      _newPasswordController.text,
      _confirmNewPasswordController.text,
    );
    setState(() => _check = check);
    if (!check.isValid) return;
    context.read<AuthBloc>().add(
      ChangePasswordSubmitted(
        userId: userId,
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmNewPassword: _confirmNewPasswordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Container(
      width: screenSize.width * 0.9,
      decoration: AppTheme.authCardDecoration(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LoginCardHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              children: [
                const Text(
                  'CHANGE PASSWORD',
                  style: AppTheme.authPageTitleStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.authSmallGap),
                Text(
                  'For your security, change the temporary password you were '
                  'given before you continue.',
                  style: AppTheme.authBodyStyle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          ChangePasswordFields(
            enabled: context.select<AuthBloc, bool>(
              (bloc) => bloc.state is! AuthChangePasswordLoading,
            ),
            currentPasswordController: _currentPasswordController,
            newPasswordController: _newPasswordController,
            confirmNewPasswordController: _confirmNewPasswordController,
            check: _check,
            onSubmitted: _submit,
          ),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    AuthBtn(
                      isLoading: state is AuthChangePasswordLoading,
                      onPressed: _submit,
                      label: 'SAVE PASSWORD',
                    ),

                    const SizedBox(height: 10),

                    if (state
                        case AuthChangePasswordError(:final message) ||
                            AuthChangePasswordNetworkError(:final message)) ...{
                      AuthErrorNotice(message: message),
                    },
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
