import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/router/login_page_order.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/login_card_header.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/login_slide_direction.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

/// The page background, logo header and card shared by every login screen.
/// Only the [child] inside the card changes between screens; [path] is the
/// address of the screen being shown.
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
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: AppTheme.authPagePadding,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppTheme.authMaxWidth),
            child: Container(
              width: double.infinity,
              decoration: AppTheme.authCardDecoration(context),
              // The card builds upward: the screen is listed first and the
              // header last, so the header is painted after the screens'
              // navigator. A navigator hides everything painted before it
              // from screen readers, which would hide the header's title.
              child: Column(
                verticalDirection: VerticalDirection.up,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
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
                                  AppTheme.authOpeningCardInterval.transform(
                                    _opening.value,
                                  )) *
                              AppTheme.authSlideDistance,
                        ),
                        child: child,
                      ),
                    ),
                  ),
                  LoginCardHeader(opening: _opening),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
