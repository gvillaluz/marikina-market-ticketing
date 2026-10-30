import 'package:marikina_market_mobile/core/errors/result.dart';
import '../entities/records_page_data.dart';
import '../entities/vendor_ticket_detail.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/ticket_receipt_proof.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/community_service_progress.dart';
import '../enums/records_filter.dart';

abstract class RecordsRepository {
  Future<Result<RecordsPageData>> loadRecords({
    required String search,
    required int offset,
    required RecordsFilter filter,
  });
  Future<Result<VendorTicketDetail>> loadDetail(int ticketId);
  Future<Result<TicketReceiptProof>> loadReceipt(int ticketId);
  Future<Result<CommunityServiceProgress>> loadServiceProgress(int ticketId);
}
