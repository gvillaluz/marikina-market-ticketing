import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/utils/unit.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/change_penalty_params.dart';
import 'package:marikina_market_mobile/features/tickets/domain/repositories/ticket_repository.dart';

class ChangePenaltyUseCase {
  final TicketRepository _repository;
  ChangePenaltyUseCase(this._repository);

  Future<Result<Unit>> call(ChangePenaltyParams params) async {
    return await _repository.changePenalty(params);
  }
}
