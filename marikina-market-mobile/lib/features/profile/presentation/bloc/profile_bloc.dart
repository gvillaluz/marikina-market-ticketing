import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/profile/domain/use_cases/change_password_use_case.dart';
import 'package:marikina_market_mobile/features/profile/domain/use_cases/change_profile_photo_use_case.dart';
import 'package:marikina_market_mobile/features/profile/domain/use_cases/edit_profile_use_case.dart';
import 'package:marikina_market_mobile/features/profile/domain/use_cases/remove_profile_photo_use_case.dart';
import 'package:marikina_market_mobile/features/profile/domain/use_cases/export_qr_use_case.dart';
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_event.dart';
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final EditProfileUseCase editProfileUseCase;
  final ChangePasswordUseCase changePasswordUseCase;
  final ChangeProfilePhotoUseCase changeProfilePhotoUseCase;
  final RemoveProfilePhotoUseCase removeProfilePhotoUseCase;
  final ExportQrUseCase? exportQrUseCase;

  ProfileBloc({
    required this.editProfileUseCase,
    required this.changePasswordUseCase,
    required this.changeProfilePhotoUseCase,
    required this.removeProfilePhotoUseCase,
    this.exportQrUseCase,
  }) : super(ProfileInitial()) {
    on<EditProfileSubmitted>(_onEditProfileSubmitted);
    on<UpdatePasswordSubmitted>(_onChangePasswordSubmitted);
    on<ChangeProfilePhoto>(_onChangeProfilePhoto);
    on<RemoveProfilePhoto>(_onRemoveProfilePhoto);
    on<ExportVendorQr>(_onExportVendorQr);
  }

  Future<void> _onExportVendorQr(
    ExportVendorQr event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is ProfileQrExportLoading) return;
    emit(ProfileQrExportLoading());
    final useCase = exportQrUseCase;
    if (useCase == null) {
      emit(ProfileQrExportError('QR export is unavailable. Please try again.'));
      return;
    }
    final result = await useCase(event.params);
    if (emit.isDone) return;
    switch (result) {
      case Success(data: final completed):
        emit(
          ProfileQrExportFinished(
            completed
                ? event.params.share
                      ? 'QR code shared.'
                      : 'QR code saved.'
                : null,
          ),
        );
      case ResultFailure(failure: final failure):
        emit(ProfileQrExportError(failure.message));
    }
  }

  Future<void> _onEditProfileSubmitted(
    EditProfileSubmitted event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is EditProfileLoading) return;
    emit(EditProfileLoading());
    final result = await editProfileUseCase(event.params);
    if (emit.isDone) return;
    switch (result) {
      case ResultFailure(failure: final failure):
        final fallback = switch (failure) {
          ValidationFailure() =>
            'Please check the profile fields and try again.',
          TokenValidationFailure() =>
            'Your session has expired. Please log in again.',
          UnauthorizedFailure() =>
            'You do not have permission to edit this profile.',
          NetworkFailure() => 'No internet connection. Please try again.',
          CacheFailure() =>
            'Your changes were saved on the server, but could not be saved on this device. Please sign in again.',
          _ => 'Unable to save your profile. Please try again.',
        };
        emit(
          EditProfileError(
            failure.message.trim().isEmpty ? fallback : failure.message,
          ),
        );
      case Success(data: final user):
        emit(ProfileUpdated(user));
    }
  }

  Future<void> _onChangePasswordSubmitted(
    UpdatePasswordSubmitted event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is ChangePasswordLoading) return;
    emit(ChangePasswordLoading());

    var result = await changePasswordUseCase(
      ChangePasswordParams(
        userId: event.userId,
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
        confirmNewPassword: event.confirmNewPassword,
      ),
    );

    if (emit.isDone) return;
    switch (result) {
      case ResultFailure(
        failure: NetworkFailure(:final message) ||
            ServerFailure(:final message),
      ):
        emit(ChangePasswordNetworkError(message));

      case ResultFailure(
        failure: ValidationFailure(:final message) ||
            UnauthorizedFailure(:final message),
      ):
        emit(ChangePasswordError(message));

      case Success():
        emit(PasswordChangedSuccessfully());

      default:
        emit(ChangePasswordNetworkError('An unexpected error occurred.'));
    }
  }

  Future<void> _onChangeProfilePhoto(
    ChangeProfilePhoto event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is ProfilePhotoLoading) return;
    emit(ProfilePhotoLoading());
    final result = await changeProfilePhotoUseCase(event.file);
    if (emit.isDone) return;

    switch (result) {
      case Success(data: final user):
        emit(ProfilePictureChanged(user));
        break;

      case ResultFailure(failure: final failure):
        emit(ChangeProfilePhotoFailed(failure.message));
        break;
    }
  }

  Future<void> _onRemoveProfilePhoto(
    RemoveProfilePhoto event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is ProfilePhotoLoading) return;
    emit(ProfilePhotoLoading());
    final result = await removeProfilePhotoUseCase();
    if (emit.isDone) return;

    switch (result) {
      case Success(data: final user):
        emit(ProfilePictureChanged(user));
        break;

      case ResultFailure(failure: final failure):
        emit(ChangeProfilePhotoFailed(failure.message));
        break;
    }
  }
}
