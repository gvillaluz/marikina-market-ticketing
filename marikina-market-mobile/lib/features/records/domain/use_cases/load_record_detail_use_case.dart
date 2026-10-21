import 'package:marikina_market_mobile/core/errors/result.dart';
import '../entities/vendor_ticket_detail.dart';
import '../repositories/records_repository.dart';

class LoadRecordDetailUseCase {
  final RecordsRepository repository;
  const LoadRecordDetailUseCase(this.repository);
  Future<Result<VendorTicketDetail>> call(int ticketId) =>
      repository.loadDetail(ticketId);
}
