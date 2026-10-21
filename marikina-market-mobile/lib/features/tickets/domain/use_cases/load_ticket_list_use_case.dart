import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/page_result.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_summary.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/features/tickets/domain/repositories/ticket_repository.dart';

class LoadTicketListUseCase {
  final TicketRepository _repository;
  LoadTicketListUseCase(this._repository);

  Future<Result<PageResult<TicketSummary>>> call(
    String search,
    int offset,
    TicketStatus status,
  ) async {
    return await _repository.loadTickets(search, offset, status);
  }
}
