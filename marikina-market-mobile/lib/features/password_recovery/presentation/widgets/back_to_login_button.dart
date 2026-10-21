import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';

class BackToLoginButton extends StatelessWidget {
  final bool enabled;

  const BackToLoginButton({super.key, this.enabled = true});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.center,
    child: TextButton(
      onPressed: enabled ? () => context.goNamed(Routes.loginName) : null,
      child: const Text('Back to login'),
    ),
  );
}
