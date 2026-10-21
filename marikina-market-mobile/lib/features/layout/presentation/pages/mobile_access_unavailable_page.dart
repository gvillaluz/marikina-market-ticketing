import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/layout/presentation/widgets/root_logout_button.dart';

class MobileAccessUnavailablePage extends StatelessWidget {
  const MobileAccessUnavailablePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Access unavailable'),
      actions: const [RootLogoutButton()],
    ),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: AppTheme.authPagePadding,
          child: Text(
            'This account does not have mobile access. Log out and sign in with a vendor or enforcer account.',
            style: AppTheme.authBodyStyle,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}
