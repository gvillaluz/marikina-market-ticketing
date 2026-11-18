import 'package:marikina_market_mobile/core/router/routes.dart';

/// Where a login screen sits along its way: a screen with a higher number is
/// further on. The login frame slides screens in from the right when the
/// number goes up and from the left when it goes down.
int loginPageOrder(String path) => switch (path) {
  Routes.login => 0,
  Routes.loginOtp => 1,
  Routes.mandatoryChangePassword => 2,
  Routes.findAccount => 1,
  Routes.forgotPasswordOption => 2,
  Routes.codeVerification => 3,
  Routes.resetPassword => 4,
  _ => 0,
};
