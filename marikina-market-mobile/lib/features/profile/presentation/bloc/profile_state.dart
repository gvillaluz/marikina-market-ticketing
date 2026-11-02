import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class EditProfileLoading extends ProfileState {}

class EditProfileError extends ProfileState {
  final String message;
  EditProfileError(this.message);
}

class ProfileUpdated extends ProfileState {
  final User user;
  ProfileUpdated(this.user);
}

class ChangePasswordLoading extends ProfileState {}

class ChangePasswordError extends ProfileState {
  final String message;
  ChangePasswordError(this.message);
}

class ChangePasswordNetworkError extends ProfileState {
  final String message;
  ChangePasswordNetworkError(this.message);
}

class PasswordChangedSuccessfully extends ProfileState {}

class ProfilePhotoLoading extends ProfileState {}

class ProfilePictureChanged extends ProfileState {
  final User user;
  ProfilePictureChanged(this.user);
}

class ChangeProfilePhotoFailed extends ProfileState {
  final String message;
  ChangeProfilePhotoFailed(this.message);
}
