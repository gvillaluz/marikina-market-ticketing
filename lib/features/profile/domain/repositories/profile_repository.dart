import 'package:image_picker/image_picker.dart';
import 'package:marikina_market_mobile/features/profile/domain/use_cases/edit_profile_params.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/utils/unit.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';

abstract class ProfileRepository {
  Future<Result<User>> updateUserInfo(EditProfileParams params);

  Future<Result<Unit>> changePassword(
    int userId,
    String currentPassword,
    String newPassword,
    String confirmNewPassword,
  );

  Future<Result<User>> changePhoto(XFile file);
  Future<Result<User>> removePhoto();
}
