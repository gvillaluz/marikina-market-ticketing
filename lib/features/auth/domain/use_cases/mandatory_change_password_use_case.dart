import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/usecases/usecase.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';
import 'package:marikina_market_mobile/features/auth/domain/repositories/auth_repository.dart';

class MandatoryChangePasswordUseCase
    extends UseCase<User, MandatoryChangePasswordParams> {
  final AuthRepository _repository;
  MandatoryChangePasswordUseCase(this._repository);

  @override
  Future<Result<User>> call(MandatoryChangePasswordParams params) async {
    if (params.currentPassword.trim().isEmpty ||
        params.newPassword.trim().isEmpty ||
        params.confirmNewPassword.trim().isEmpty) {
      return Result.failure(
        ValidationFailure('All password fields are required.'),
      );
    }

    if (params.newPassword.length < 8) {
      return Result.failure(
        ValidationFailure('New password must be at least 8 characters long.'),
      );
    }

    if (params.newPassword != params.confirmNewPassword) {
      return Result.failure(ValidationFailure('New passwords do not match.'));
    }

    if (params.currentPassword == params.newPassword) {
      return Result.failure(
        ValidationFailure(
          'New password cannot be the same as your current password.',
        ),
      );
    }

    return await _repository.mandatoryChangePassword(
      params.userId,
      params.currentPassword,
      params.newPassword,
      params.confirmNewPassword,
    );
  }
}

class MandatoryChangePasswordParams {
  final int userId;
  final String currentPassword;
  final String newPassword;
  final String confirmNewPassword;

  MandatoryChangePasswordParams({
    required this.userId,
    required this.currentPassword,
    required this.newPassword,
    required this.confirmNewPassword,
  });
}
