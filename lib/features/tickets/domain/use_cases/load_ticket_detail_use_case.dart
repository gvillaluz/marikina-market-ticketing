import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_detail.dart';
import 'package:marikina_market_mobile/features/tickets/domain/repositories/ticket_repository.dart';

class LoadTicketDetailUseCase {
  final TicketRepository _repository;
  LoadTicketDetailUseCase(this._repository);

  Future<Result<TicketDetail>> call(int ticketId) async {
    return await _repository.getTicketDetail(ticketId);
  }
}