import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_event.dart';

class RootLogoutButton extends StatefulWidget {
  const RootLogoutButton({super.key});

  @override
  State<RootLogoutButton> createState() => _RootLogoutButtonState();
}

class _RootLogoutButtonState extends State<RootLogoutButton> {
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: _isLoggingOut ? 'Logging out' : 'Logout',
    onPressed: _isLoggingOut
        ? null
        : () {
            setState(() => _isLoggingOut = true);
            context.read<AuthBloc>().add(LogoutUser(false));
          },
    icon: _isLoggingOut
        ? SizedBox.square(
            dimension: AppTheme.buttonIconSize,
            child: CircularProgressIndicator(
              value: MediaQuery.disableAnimationsOf(context) ? 0.75 : null,
              strokeWidth: AppTheme.buttonProgressStrokeWidth,
              semanticsLabel: 'Logging out',
            ),
          )
        : const Icon(Icons.logout),
  );
}
