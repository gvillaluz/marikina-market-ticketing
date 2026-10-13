import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/usecases/usecase.dart';
import 'package:marikina_market_mobile/core/utils/unit.dart';
import 'package:marikina_market_mobile/features/profile/domain/repositories/profile_repository.dart';

class ChangePasswordUseCase extends UseCase<Unit, ChangePasswordParams>{
  final ProfileRepository _repository;
  ChangePasswordUseCase(this._repository);

  @override
  Future<Result<Unit>> call(ChangePasswordParams params) async {
    if (params.currentPassword.trim().isEmpty ||
        params.newPassword.trim().isEmpty ||
        params.confirmNewPassword.trim().isEmpty) {
      return Result.failure(ValidationFailure('All password fields are required.'));
    }

    if (params.newPassword.length < 8) {
      return Result.failure(ValidationFailure('New password must be at least 8 characters long.'));
    }

    if (params.newPassword != params.confirmNewPassword) {
      return Result.failure(ValidationFailure('New passwords do not match.'));
    }

    if (params.currentPassword == params.newPassword) {
      return Result.failure(ValidationFailure('New password cannot be the same as your current password.'));
    }

    return await _repository.changePassword(
      params.userId, 
      params.currentPassword, 
      params.newPassword, 
      params.confirmNewPassword
    );
  }
}

class ChangePasswordParams {
  final int userId;
  final String currentPassword;
  final String newPassword;
  final String confirmNewPassword;

  ChangePasswordParams({
    required this.userId,
    required this.currentPassword,
    required this.newPassword,
    required this.confirmNewPassword
  });
}