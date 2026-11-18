import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marikina_market_mobile/core/router/login_page_order.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/login_band.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/login_slide_direction.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

/// The page shared by every login screen: the navy band, the screen and the
/// note at the bottom. Only the [child] screen changes between screens; [path]
/// is the address of the screen being shown.
class LoginFrame extends StatefulWidget {
  final String path;
  final Widget child;
  const LoginFrame({required this.path, required this.child, super.key});

  @override
  State<LoginFrame> createState() => _LoginFrameState();
}

class _LoginFrameState extends State<LoginFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _opening = AnimationController(
    vsync: this,
    duration: AppTheme.authOpeningDuration,
  );
  bool _openingStarted = false;
  bool _forward = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Plays once, when the frame first appears.
    if (_openingStarted) return;
    _openingStarted = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _opening.value = 1;
    } else {
      _opening.forward();
    }
  }

  @override
  void dispose() {
    _opening.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LoginFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _forward = loginPageOrder(widget.path) >= loginPageOrder(oldWidget.path);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.authPageSystemBarStyle,
      child: LayoutBuilder(
        builder: (context, viewport) => SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: viewport.maxHeight),
            // The screen and the band come first, the note at the bottom
            // last. The band (built upward, after the screen) and the note
            // are both painted after the screens' navigator, which hides
            // everything painted before it from screen readers.
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  verticalDirection: VerticalDirection.up,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppTheme.authMaxWidth,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: FadeTransition(
                          alwaysIncludeSemantics: true,
                          opacity: _opening.drive(
                            CurveTween(curve: AppTheme.authOpeningCardInterval),
                          ),
                          child: AnimatedBuilder(
                            animation: _opening,
                            child: ClipRect(
                              child: LoginSlideDirection(
                                forward: _forward,
                                child: widget.child,
                              ),
                            ),
                            builder: (context, child) => Transform.translate(
                              offset: Offset(
                                0,
                                (1 -
                                        AppTheme.authOpeningCardInterval
                                            .transform(_opening.value)) *
                                    AppTheme.authSlideDistance,
                              ),
                              child: child,
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnnotatedRegion<SystemUiOverlayStyle>(
                      value: AppTheme.authBandSystemBarStyle,
                      child: LoginBand(opening: _opening),
                    ),
                  ],
                ),
                SafeArea(
                  top: false,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppTheme.authMaxWidth,
                    ),
                    child: const SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: AppTheme.authNotePadding,
                        child: Text(
                          'Need an account? Ask your Head Admin to add one '
                          'for you.',
                          style: AppTheme.authNoteStyle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
