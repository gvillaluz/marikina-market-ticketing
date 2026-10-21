import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/warning_ordinance.dart';
import 'package:marikina_market_mobile/features/tickets/domain/repositories/inspection_repository.dart';

class CheckWarningOrdinancesUseCase {
  final InspectionRepository _repository;

  CheckWarningOrdinancesUseCase(this._repository);

  Future<Result<List<WarningOrdinance>>> call(
    List<int> ordinanceIds,
    int vendorId,
  ) {
    if (ordinanceIds.isEmpty || ordinanceIds.any((id) => id <= 0)) {
      return Future.value(
        Result.failure(ValidationFailure('Select at least one ordinance.')),
      );
    }
    if (vendorId <= 0) {
      return Future.value(
        Result.failure(ValidationFailure('Vendor must be valid.')),
      );
    }
    return _repository.checkWarningOrdinances(ordinanceIds, vendorId);
  }
}
