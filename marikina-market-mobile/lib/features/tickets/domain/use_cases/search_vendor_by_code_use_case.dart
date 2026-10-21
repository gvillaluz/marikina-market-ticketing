import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/vendor_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/repositories/inspection_repository.dart';

class SearchVendorByCodeUseCase {
  final InspectionRepository _repository;
  SearchVendorByCodeUseCase(this._repository);

  Future<Result<VendorSummary>> call(String codeValue) async {
    return await _repository.getVendorByCode(codeValue);
  }
}