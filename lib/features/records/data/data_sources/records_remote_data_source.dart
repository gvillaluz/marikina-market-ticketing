import 'package:marikina_market_mobile/core/network/client.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:marikina_market_mobile/core/errors/exceptions.dart';
import 'package:marikina_market_mobile/core/shared/data/models/ticket_receipt_proof_model.dart';
import 'package:marikina_market_mobile/core/shared/data/models/community_service_progress_model.dart';
import '../../domain/enums/records_filter.dart';
import '../models/records_page_model.dart';
import '../models/vendor_ticket_detail_model.dart';

class RecordsRemoteDataSource {
  final ApiClient client;
  const RecordsRemoteDataSource(this.client);
  static const maxReceiptBytes = 5 * 1024 * 1024;
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

  Future<TicketReceiptProofModel> submitReceipt(int id, String path) async {
    final extension = File(
      path,
    ).uri.pathSegments.last.split('.').last.toLowerCase();
    if (!const ['jpg', 'jpeg', 'png'].contains(extension)) {
      throw ValidationException('Choose a JPG, JPEG, or PNG photo.');
    }
    final file = await File(path).open();
    final List<int> bytes;
    try {
      bytes = await file.read(maxReceiptBytes + 1);
    } finally {
      await file.close();
    }
    if (bytes.isEmpty || bytes.length > maxReceiptBytes) {
      throw ValidationException(
        'Receipt photo must be nonempty and 5 MB or smaller.',
      );
    }
    final jpeg =
        bytes.length >= 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255;
    const pngSignature = [137, 80, 78, 71, 13, 10, 26, 10];
    final png =
        bytes.length >= 8 &&
        List.generate(
          8,
          (index) => bytes[index] == pngSignature[index],
        ).every((matches) => matches);
    if ((!jpeg && !png) ||
        (extension == 'png' && !png) ||
        (extension != 'png' && !jpeg)) {
      throw ValidationException('Choose a valid JPG, JPEG, or PNG photo.');
    }
    final form = FormData.fromMap({
      'proof_file': MultipartFile.fromBytes(
        bytes,
        filename: png ? 'proof.png' : 'proof.jpg',
        contentType: DioMediaType('image', png ? 'png' : 'jpeg'),
      ),
    });
    final response = await client.post(
      '/vendor/tickets/$id/settlement/receipt',
      data: form,
      options: Options(
        contentType: 'multipart/form-data; boundary=${form.boundary}',
      ),
    );
    return TicketReceiptProofModel.fromJson(
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
