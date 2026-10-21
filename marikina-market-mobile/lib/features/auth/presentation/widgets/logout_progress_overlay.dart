import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';

class LogoutProgressOverlay extends StatelessWidget {
  final Widget child;
  const LogoutProgressOverlay({required this.child, super.key});

  @override
  Widget build(BuildContext context) => BlocSelector<AuthBloc, AuthState, bool>(
    selector: (state) => state is AuthLoggingOut,
    builder: (context, loading) => Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (loading) ...[
          const ModalBarrier(
            dismissible: false,
            color: AppTheme.authLogoutBarrierColor,
          ),
          Center(
            child: Padding(
              padding: AppTheme.authPagePadding,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppTheme.authLogoutMaxWidth,
                ),
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: AppTheme.controlRadius,
                  child: Padding(
                    padding: AppTheme.authCardPadding,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox.square(
                          dimension: AppTheme.authLogoutIndicatorSize,
                          child: CircularProgressIndicator(
                            value: MediaQuery.disableAnimationsOf(context)
                                ? .75
                                : null,
                          ),
                        ),
                        const SizedBox(height: AppTheme.authGap),
                        Semantics(
                          liveRegion: true,
                          child: const Text(
                            'Signing out…',
                            style: AppTheme.authBodyStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
