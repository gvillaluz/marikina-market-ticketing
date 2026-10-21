import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/inspection_ticket_summary.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/page_result.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/domain/repositories/inspection_repository.dart';

class LoadInspectionListUseCase {
  final InspectionRepository _repository;
  LoadInspectionListUseCase(this._repository);

  Future<Result<PageResult<InspectionTicketSummary>>> call(
    String search,
    int offset,
    ViolationType type,
  ) async {
    return await _repository.loadInspections(search, offset, type);
  }
}
