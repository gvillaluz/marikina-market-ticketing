import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/vendor_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/repositories/inspection_repository.dart';

class SearchVendorByStallUseCase {
  final InspectionRepository _repository;
  SearchVendorByStallUseCase(this._repository);

  Future<Result<List<VendorSummary>>> call(String stallNumber) async {
    return await _repository.getVendorByStall(stallNumber);
  }
}