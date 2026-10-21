import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/repositories/inspection_repository.dart';

class GetFineSummaryUseCase {
  final InspectionRepository _repository;
  GetFineSummaryUseCase(this._repository);

  Future<Result<FineSummary>> call(List<int> ordinanceIds, int? vendorId) async {
    if (vendorId == null) {
      return Result.failure(
        ValidationFailure("Vendor must not be empty.")
      );
    }
    return await _repository.getTicketFineSummary(ordinanceIds, vendorId);
  }
}