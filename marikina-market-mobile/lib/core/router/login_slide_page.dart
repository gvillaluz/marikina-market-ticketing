import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/login_slide_direction.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

/// A login screen that slides in a short way and fades in, from the right
/// when moving forward and from the left when moving back. The screen it
/// replaces disappears at once, so only one screen moves at a time and the
/// card never has to fit two screens together.
///
/// While two screens are in place, the navigator takes the height of the top
/// one and squeezes the other into it. Each screen therefore keeps its own
/// height and is trimmed instead: the squeezed screen is hidden or fading in
/// at that moment, and the navigator follows the new screen's height once
/// the change has finished.
CustomTransitionPage<void> loginSlidePage(
  BuildContext context,
  GoRouterState state, {
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    name: state.name,
    child: child,
    // Never zero: Flutter itself shortens these when the device asks for no
    // animations, and a zero-length route change completes before the
    // navigator has finished handling it.
    transitionDuration: AppTheme.authSlideDuration,
    reverseTransitionDuration: AppTheme.authSlideDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, screen) {
      final child = UnconstrainedBox(
        constrainedAxis: Axis.horizontal,
        alignment: Alignment.topCenter,
        clipBehavior: Clip.hardEdge,
        child: screen,
      );
      if (MediaQuery.disableAnimationsOf(context)) return child;
      final forward = LoginSlideDirection.forwardOf(context);
      return AnimatedBuilder(
        animation: Listenable.merge([animation, secondaryAnimation]),
        child: child,
        builder: (context, child) {
          final leaving = animation.status == AnimationStatus.reverse;
          final covered =
              secondaryAnimation.status == AnimationStatus.forward ||
              secondaryAnimation.status == AnimationStatus.completed;
          if (leaving || covered) return Opacity(opacity: 0, child: child);
          final shown = Curves.easeOutCubic.transform(
            animation.value < 1 - secondaryAnimation.value
                ? animation.value
                : 1 - secondaryAnimation.value,
          );
          return Opacity(
            opacity: shown,
            alwaysIncludeSemantics: true,
            child: Transform.translate(
              offset: Offset(
                (forward ? 1 : -1) * (1 - shown) * AppTheme.authSlideDistance,
                0,
              ),
              child: child,
            ),
          );
        },
      );
    },
  );
}
