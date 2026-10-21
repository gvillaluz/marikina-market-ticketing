import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';
import 'package:marikina_market_mobile/features/auth/domain/repositories/auth_repository.dart';

class CheckAuthStatusUseCase {
  final AuthRepository _repository;
  const CheckAuthStatusUseCase(this._repository);

  Future<Result<User?>> call() async {
    return await _repository.checkAuth();
  }
}
