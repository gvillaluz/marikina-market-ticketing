import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/router/route_args.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/widgets/recovery_code_card.dart';

class CodeValidationPage extends StatelessWidget {
  final CodeValidationArgs args;
  const CodeValidationPage({required this.args, super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: AppTheme.authPagePadding,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppTheme.authMaxWidth),
            child: RecoveryCodeCard(args: args),
          ),
        ),
      ),
    ),
  );
}
