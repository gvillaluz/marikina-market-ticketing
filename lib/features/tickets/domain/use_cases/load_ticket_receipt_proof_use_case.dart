import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/usecases/usecase.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/ticket_receipt_proof.dart';
import 'package:marikina_market_mobile/features/tickets/domain/repositories/ticket_repository.dart';

class LoadTicketReceiptProofUseCase
    implements UseCase<TicketReceiptProof, int> {
  final TicketRepository _repository;

  LoadTicketReceiptProofUseCase(this._repository);

  @override
  Future<Result<TicketReceiptProof>> call(int ticketId) {
    return _repository.getTicketReceiptProof(ticketId);
  }
}
