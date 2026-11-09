import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/market_section.dart';
import 'package:marikina_market_mobile/features/tickets/domain/repositories/inspection_repository.dart';

class GetMarketSectionsUseCase {
  final InspectionRepository _repository;
  const GetMarketSectionsUseCase(this._repository);
  Future<Result<List<MarketSection>>> call() => _repository.getMarketSections();
}
