import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';
import 'package:marikina_market_mobile/features/profile/domain/repositories/profile_repository.dart';

class RemoveProfilePhotoUseCase {
  final ProfileRepository _repository;
  const RemoveProfilePhotoUseCase(this._repository);

  Future<Result<User>> call() async => _repository.removePhoto();
}
