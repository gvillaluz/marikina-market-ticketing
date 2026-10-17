import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/utils/unit.dart';
import 'package:marikina_market_mobile/features/auth/domain/repositories/auth_repository.dart';

class RefreshTokensUseCase {
  final AuthRepository _repository;
  Future<Result<Unit>>? _refreshInFlight;

  RefreshTokensUseCase(this._repository);

  Future<Result<Unit>> call() {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;

    final refresh = _repository.refreshTokens();
    _refreshInFlight = refresh;
    return refresh.whenComplete(() {
      if (identical(_refreshInFlight, refresh)) {
        _refreshInFlight = null;
      }
    });
  }

  Future<Result<Unit>> waitForOngoingRefresh() async {
    final inFlight = _refreshInFlight;
    if (inFlight == null) return Result.success(unit);
    return await inFlight;
  }
}
