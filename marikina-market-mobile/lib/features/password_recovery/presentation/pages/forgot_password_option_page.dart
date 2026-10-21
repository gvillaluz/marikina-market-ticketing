import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/auth_error_notice.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/router/route_args.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/entities/account_lookup.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_bloc.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_event.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_state.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/widgets/factor_option_btn.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/widgets/back_to_login_button.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/login_card_header.dart';

class ForgotPasswordOptionPage extends StatefulWidget {
  final ForgotPasswordOptionArgs args;
  const ForgotPasswordOptionPage({required this.args, super.key});

  @override
  State<StatefulWidget> createState() => _ForgotPasswordOptionPageState();
}

class _ForgotPasswordOptionPageState extends State<ForgotPasswordOptionPage> {
  AccountLookup? _account;

  @override
  void initState() {
    super.initState();

    _account = widget.args.account;

    if (_account == null) {
      context.read<PasswordRecoveryBloc>().add(
        FindAccount(widget.args.username),
      );
    }
  }

  void _onTap(BuildContext context, String channel, AccountLookup account) {
    if (channel != 'email' && channel != 'phone') {
      context.pop();
    } else {
      context.pushNamed(
        Routes.codeVerificationName,
        extra: CodeValidationArgs(
          username: widget.args.username,
          channel: channel,
          account: account,
        ),
      );
    }
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
                              'Choose a recovery method',
                              style: AppTheme.authPageTitleStyle,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Select how you would like to access your account.',
                              style: TextStyle(
                                color: AppTheme.authVerificationBodyColor,
                                fontSize: AppTheme.bodyFontSize,
                              ),
                            ),
                            const SizedBox(height: 20),
                            BlocBuilder<
                              PasswordRecoveryBloc,
                              PasswordRecoveryState
                            >(
                              builder: (context, state) {
                                if (_account != null) {
                                  return _buildContent(context, _account!);
                                }

                                if (state is SearchAccountLoading) {
                                  return const SizedBox(
                                    height: 180,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  );
                                }

                                if (state is SearchAccountFailed) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    child: AuthErrorNotice(
                                      message: state.message,
                                    ),
                                  );
                                }

                                if (state is AccountFound) {
                                  return _buildContent(
                                    context,
                                    state.accountLookup,
                                  );
                                }

                                return const SizedBox.shrink();
                              },
                            ),
                            BackToLoginButton(
                              enabled: context
                                  .select<PasswordRecoveryBloc, bool>(
                                    (bloc) =>
                                        bloc.state is! SearchAccountLoading,
                                  ),
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
    );
  }

  Widget _buildContent(BuildContext context, AccountLookup account) {
    return Column(
      children: [
        if (account.maskedEmail.trim().isNotEmpty) ...[
          FactorOptionBtn(
            icon: Icons.email,
            title: 'Reset via Email',
            subtitle:
                'To reset your password, a code will be sent to your email.',
            onTap: () => _onTap(context, "email", account),
          ),
          const SizedBox(height: 10),
        ],
        if (account.masketPhoneNumber.trim().isNotEmpty) ...[
          FactorOptionBtn(
            icon: Icons.phone,
            title: 'Reset via SMS number',
            subtitle:
                'To reset your password, a code will be sent to your SMS number.',
            onTap: () => _onTap(context, "phone", account),
          ),
          const SizedBox(height: 10),
        ],
        FactorOptionBtn(
          icon: Icons.lock,
          title: 'Continue with password',
          subtitle: 'Use your password instead.',
          onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
        ),
      ],
    );
  }
}
