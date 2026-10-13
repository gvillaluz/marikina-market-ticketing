import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/ticket_receipt_proof.dart';
import '../repositories/records_repository.dart';

class LoadVendorReceiptUseCase {
  final RecordsRepository repository;
  const LoadVendorReceiptUseCase(this.repository);
  Future<Result<TicketReceiptProof>> call(int ticketId) =>
      repository.loadReceipt(ticketId);
}
