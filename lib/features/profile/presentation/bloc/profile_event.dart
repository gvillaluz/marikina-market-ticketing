import 'package:image_picker/image_picker.dart';
import 'package:marikina_market_mobile/features/profile/domain/use_cases/edit_profile_params.dart';
import 'package:marikina_market_mobile/features/profile/domain/use_cases/export_qr_params.dart';

abstract class ProfileEvent {}

class EditProfileSubmitted extends ProfileEvent {
  final EditProfileParams params;
  EditProfileSubmitted(this.params);
}

class UpdatePasswordSubmitted extends ProfileEvent {
  final int userId;
  final String currentPassword;
  final String newPassword;
  final String confirmNewPassword;

  UpdatePasswordSubmitted({
    required this.userId,
    required this.currentPassword,
    required this.newPassword,
    required this.confirmNewPassword,
  });
}

class ChangeProfilePhoto extends ProfileEvent {
  final XFile file;
  ChangeProfilePhoto({required this.file});
}

class RemoveProfilePhoto extends ProfileEvent {}

class ExportVendorQr extends ProfileEvent {
  final ExportQrParams params;
  ExportVendorQr(this.params);
}
