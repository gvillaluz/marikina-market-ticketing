import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/ticket_receipt_proof.dart';
import '../entities/submit_vendor_receipt_params.dart';
import '../repositories/records_repository.dart';

class SubmitVendorReceiptUseCase {
  final RecordsRepository repository;
  const SubmitVendorReceiptUseCase(this.repository);
  Future<Result<TicketReceiptProof>> call(SubmitVendorReceiptParams params) =>
      repository.submitReceipt(params);
}
