import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/auth_error_notice.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/reveal_message.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/router/route_args.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/auth_btn.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_bloc.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_event.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_state.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/widgets/back_to_login_button.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/widgets/recovery_step_counter.dart';

class FindAccountPage extends StatefulWidget {
  const FindAccountPage({super.key});

  @override
  State<StatefulWidget> createState() => _FindAccountPageState();
}

class _FindAccountPageState extends State<FindAccountPage> {
  final usernameController = TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  void _searchAccount() {
    if (usernameController.text.isNotEmpty) {
      context.read<PasswordRecoveryBloc>().add(
        FindAccount(usernameController.text.trim()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PasswordRecoveryBloc, PasswordRecoveryState>(
      listener: (context, state) {
        if (state is AccountFound) {
          context.pushNamed(
            Routes.forgotPasswordOptionName,
            extra: ForgotPasswordOptionArgs(
              username: usernameController.text.trim(),
            ),
          );
        }
      },
      child: Padding(
        padding: AppTheme.authCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RecoveryStepCounter(step: 1),
            const Text('Find your account', style: AppTheme.authPageTitleStyle),
            const SizedBox(height: 4),
            const Text(
              'Enter your username to continue.',
              style: TextStyle(
                color: AppTheme.authVerificationBodyColor,
                fontSize: AppTheme.bodyFontSize,
              ),
            ),
            const SizedBox(height: 24),
            const Text('USERNAME'),
            const SizedBox(height: 7),
            TextField(
              enabled: context.select<PasswordRecoveryBloc, bool>(
                (bloc) => bloc.state is! SearchAccountLoading,
              ),
              autofillHints: const [AutofillHints.username],
              autocorrect: false,
              controller: usernameController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _searchAccount(),
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_rounded),
                hintText: 'Enter your username',
                hintStyle: const TextStyle(
                  color: AppColors.lightGrey,
                  fontSize: AppTheme.bodyFontSize,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            BlocBuilder<PasswordRecoveryBloc, PasswordRecoveryState>(
              builder: (context, state) {
                return Column(
                  children: [
                    AuthBtn(
                      isLoading: state is SearchAccountLoading,
                      onPressed: _searchAccount,
                      label: 'Continue',
                    ),
                    RevealMessage(
                      child: state is SearchAccountFailed
                          ? Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: AuthErrorNotice(message: state.message),
                            )
                          : null,
                    ),
                    BackToLoginButton(enabled: state is! SearchAccountLoading),
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
