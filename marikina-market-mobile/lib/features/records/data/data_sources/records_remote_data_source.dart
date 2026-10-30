import 'package:marikina_market_mobile/core/network/client.dart';
import 'package:marikina_market_mobile/core/shared/data/models/ticket_receipt_proof_model.dart';
import 'package:marikina_market_mobile/core/shared/data/models/community_service_progress_model.dart';
import '../../domain/enums/records_filter.dart';
import '../models/records_page_model.dart';
import '../models/vendor_ticket_detail_model.dart';

class RecordsRemoteDataSource {
  final ApiClient client;
  const RecordsRemoteDataSource(this.client);
  Future<TicketReceiptProofModel> loadReceipt(int id) async {
    final response = await client.get('/vendor/tickets/$id/settlement/receipt');
    return TicketReceiptProofModel.fromJson(
      response.data as Map<String, Object?>,
    );
  }

  Future<CommunityServiceProgressModel> loadServiceProgress(int id) async {
    final response = await client.get(
      '/vendor/tickets/$id/settlement/community-service',
    );
    return CommunityServiceProgressModel.fromJson(
      response.data as Map<String, Object?>,
    );
  }

  Future<RecordsPageModel> loadRecords(
    String search,
    int offset,
    RecordsFilter filter,
  ) async {
    final response = await client.get(
      '/vendor/tickets/inspections',
      queryParameters: <String, Object?>{
        'offset': offset,
        if (filter.apiValue != null) 'type': filter.apiValue,
        if (search.isNotEmpty) 'search': search,
      },
    );
    return RecordsPageModel.fromJson(response.data as Map<String, Object?>);
  }

  Future<VendorTicketDetailModel> loadDetail(int id) async {
    final response = await client.get('/vendor/tickets/$id');
    return VendorTicketDetailModel.fromJson(
      response.data as Map<String, Object?>,
    );
  }
}
