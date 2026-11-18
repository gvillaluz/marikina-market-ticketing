import 'package:flutter/widgets.dart';

/// Tells the login screens which way they are being moved: forward screens
/// slide in from the right, earlier ones from the left.
class LoginSlideDirection extends InheritedWidget {
  final bool forward;
  const LoginSlideDirection({
    required this.forward,
    required super.child,
    super.key,
  });

  static bool forwardOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<LoginSlideDirection>()
          ?.forward ??
      true;

  @override
  bool updateShouldNotify(LoginSlideDirection oldWidget) =>
      forward != oldWidget.forward;
}
