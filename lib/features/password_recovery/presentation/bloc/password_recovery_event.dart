abstract class PasswordRecoveryEvent {}

class FindAccount extends PasswordRecoveryEvent {
  final String username;
  FindAccount(this.username);
}

class SendOtp extends PasswordRecoveryEvent {
  final String username;
  final String channel;

  SendOtp({required this.username, required this.channel});
}

class VerifyCode extends PasswordRecoveryEvent {
  final String username;
  final String code;

  VerifyCode(this.username, this.code);
}

class ResetPassword extends PasswordRecoveryEvent {
  final String username;
  final String newPassword;
  final String confirmNewPassword;
  final String resetToken;

  ResetPassword(
    this.username,
    this.newPassword,
    this.confirmNewPassword,
    this.resetToken,
  );
}
