import 'package:marikina_market_mobile/features/password_recovery/domain/entities/account_lookup.dart';

class ForgotPasswordOptionArgs {
  final String username;
  final AccountLookup? account;

  ForgotPasswordOptionArgs({required this.username, this.account});
}

class CodeValidationArgs {
  final String username;
  final String channel;
  final AccountLookup account;

  CodeValidationArgs({
    required this.username,
    required this.channel,
    required this.account,
  });
}

class ResetPasswordArgs {
  final String username;
  final String resetToken;

  ResetPasswordArgs({required this.username, required this.resetToken});
}
