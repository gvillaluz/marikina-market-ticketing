import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';
import 'package:marikina_market_mobile/features/profile/domain/repositories/profile_repository.dart';

class ChangeProfilePhotoUseCase {
  final ProfileRepository _repository;
  const ChangeProfilePhotoUseCase(this._repository);

  Future<Result<User>> call(XFile file) async => _repository.changePhoto(file);
}
