import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/penalty_options.dart';
import 'package:marikina_market_mobile/features/tickets/domain/repositories/ticket_repository.dart';

class LoadPenaltyOptionsUseCase {
  final TicketRepository _repository;
  LoadPenaltyOptionsUseCase(this._repository);

  Future<Result<PenaltyOptions>> call(int ticketId) async {
    return await _repository.getPenaltyOptions(ticketId);
  }
}
