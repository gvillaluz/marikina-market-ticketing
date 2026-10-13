import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/usecases/usecase.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/submit_ticket_receipt_proof_params.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/ticket_receipt_proof.dart';
import 'package:marikina_market_mobile/features/tickets/domain/repositories/ticket_repository.dart';

class SubmitTicketReceiptProofUseCase
    implements UseCase<TicketReceiptProof, SubmitTicketReceiptProofParams> {
  final TicketRepository _repository;

  SubmitTicketReceiptProofUseCase(this._repository);

  @override
  Future<Result<TicketReceiptProof>> call(
    SubmitTicketReceiptProofParams params,
  ) {
    if (!params.proofFile.existsSync()) {
      return Future.value(
        Result.failure(ValidationFailure('A settlement receipt is required.')),
      );
    }
    return _repository.submitTicketReceiptProof(
      params.ticketId,
      params.proofFile,
    );
  }
}
