import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/page_result.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/vendor_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/repositories/inspection_repository.dart';

class SearchBusinessesUseCase {
  final InspectionRepository _repository;
  const SearchBusinessesUseCase(this._repository);
  Future<Result<PageResult<VendorSummary>>> call(String search) =>
      _repository.searchBusinesses(search);
}
