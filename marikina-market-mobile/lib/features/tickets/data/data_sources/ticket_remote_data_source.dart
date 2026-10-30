import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:marikina_market_mobile/core/errors/exceptions.dart';
import 'package:marikina_market_mobile/core/network/client.dart';
import 'package:marikina_market_mobile/core/shared/data/models/page_result_model.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/core/shared/data/models/community_service_progress_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ticket_detail_model.dart';
import 'package:marikina_market_mobile/core/shared/data/models/ticket_receipt_proof_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ticket_summary_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/submit_community_service_log_params.dart';

abstract class TicketRemoteDataSource {
  Future<PageResultModel<TicketSummaryModel>> loadTickets(
    String search,
    int offset,
    TicketStatus? status,
  );
  Future<TicketDetailModel> getTicketDetailById(int ticketId);
  Future<TicketReceiptProofModel> getTicketReceiptProof(int ticketId);
  Future<CommunityServiceProgressModel> getCommunityServiceProgress(
    int ticketId,
  );
  Future<TicketReceiptProofModel> submitTicketReceiptProof(
    int ticketId,
    File proofFile,
  );
  Future<CommunityServiceProgressModel> submitCommunityServiceLog(
    SubmitCommunityServiceLogParams params,
  );
}

class TicketRemoteDataSourceImpl implements TicketRemoteDataSource {
  final ApiClient apiClient;
  static const _submissionStorage = FlutterSecureStorage();
  String _submissionKey(int id, String action) =>
      'ticket_settlement_${id}_$action';
  Future<String> _submissionId(int id, String action) async {
    final key = _submissionKey(id, action);
    final pending = await _submissionStorage.read(key: key);
    if (pending != null) return pending;
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final value = [
      hex.substring(0, 8),
      hex.substring(8, 12),
      hex.substring(12, 16),
      hex.substring(16, 20),
      hex.substring(20),
    ].join('-');
    await _submissionStorage.write(key: key, value: value);
    return value;
  }

  Future<void> _reconcileSubmission(
    int id,
    String action,
    Iterable<Object?> savedIds,
  ) async {
    final key = _submissionKey(id, action);
    final pending = await _submissionStorage.read(key: key);
    if (pending != null && savedIds.contains(pending)) {
      await _submissionStorage.delete(key: key);
    }
  }

  TicketRemoteDataSourceImpl(this.apiClient);

  @override
  Future<PageResultModel<TicketSummaryModel>> loadTickets(
    String search,
    int offset,
    TicketStatus? status,
  ) async {
    try {
      final response = await apiClient.get(
        '/enforcer/tickets',
        queryParameters: <String, Object?>{
          'offset': offset,
          if (status != null) 'status': status.value,
          if (search.isNotEmpty) 'search': search,
        },
      );
      final data = response.data;

      return PageResultModel.fromJson(
        data,
        (json) => TicketSummaryModel.fromJson(json),
      );
    } on DioException catch (error) {
      _throwRequestException(error, 'Unable to load tickets.');
    }
  }

  @override
  Future<TicketDetailModel> getTicketDetailById(int ticketId) async {
    try {
      final response = await apiClient.get('/enforcer/tickets/$ticketId');
      return TicketDetailModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      _throwRequestException(error, 'Unable to load ticket details.');
    }
  }

  @override
  Future<TicketReceiptProofModel> getTicketReceiptProof(int ticketId) async {
    try {
      final response = await apiClient.get(
        '/enforcer/tickets/$ticketId/settlement/receipt',
      );
      final model = TicketReceiptProofModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      await _reconcileSubmission(ticketId, 'receipt', [
        (response.data as Map)['submission_id'],
      ]);
      return model;
    } on DioException catch (error) {
      _throwRequestException(error, 'Unable to load settlement receipt.');
    }
  }

  @override
  Future<CommunityServiceProgressModel> getCommunityServiceProgress(
    int ticketId,
  ) async {
    try {
      final response = await apiClient.get(
        '/enforcer/tickets/$ticketId/settlement/community-service',
      );
      final model = CommunityServiceProgressModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      final entries = (response.data as Map)['entries'] as List? ?? const [];
      await _reconcileSubmission(
        ticketId,
        'service',
        entries.map((e) => (e as Map)['submission_id']),
      );
      return model;
    } on DioException catch (error) {
      _throwRequestException(
        error,
        'Unable to load community service progress.',
      );
    }
  }

  @override
  Future<TicketReceiptProofModel> submitTicketReceiptProof(
    int ticketId,
    File proofFile,
  ) async {
    try {
      final formData = FormData.fromMap({
        'proof_file': await MultipartFile.fromFile(proofFile.path),
        'submission_id': await _submissionId(ticketId, 'receipt'),
      });
      final response = await apiClient.post(
        '/enforcer/tickets/$ticketId/settlement/receipt',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data; boundary=${formData.boundary}',
        ),
      );
      final model = TicketReceiptProofModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      await _reconcileSubmission(ticketId, 'receipt', [
        (response.data as Map)['submission_id'],
      ]);
      await _submissionStorage.delete(key: _submissionKey(ticketId, 'receipt'));
      return model;
    } on DioException catch (error) {
      _throwRequestException(error, 'Unable to save settlement receipt.');
    }
  }

  @override
  Future<CommunityServiceProgressModel> submitCommunityServiceLog(
    SubmitCommunityServiceLogParams params,
  ) async {
    try {
      final formData = FormData.fromMap({
        'proof_file': await MultipartFile.fromFile(params.proofFile.path),
        'service_date': params.serviceDate.toIso8601String(),
        'hours_worked': params.hoursWorked,
        'submission_id': await _submissionId(params.ticketId, 'service'),
      });
      final response = await apiClient.post(
        '/enforcer/tickets/${params.ticketId}/settlement/community-service',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data; boundary=${formData.boundary}',
        ),
      );
      final model = CommunityServiceProgressModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      final entries = (response.data as Map)['entries'] as List? ?? const [];
      await _reconcileSubmission(
        params.ticketId,
        'service',
        entries.map((e) => (e as Map)['submission_id']),
      );
      await _submissionStorage.delete(
        key: _submissionKey(params.ticketId, 'service'),
      );
      return model;
    } on DioException catch (error) {
      _throwRequestException(error, 'Unable to save community service entry.');
    }
  }

  Never _throwRequestException(DioException error, String fallbackMessage) {
    final responseData = error.response?.data;
    final message = responseData is Map<String, dynamic>
        ? responseData['message'] as String? ?? fallbackMessage
        : fallbackMessage;

    if (error.response?.statusCode == 400 ||
        error.response?.statusCode == 422) {
      throw ValidationException(message);
    }
    if (error.response?.statusCode == 401 ||
        error.response?.statusCode == 403) {
      throw UnauthorizedException(message);
    }
    if (error.response?.statusCode == 404) {
      throw NotFoundException(message);
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.receiveTimeout) {
      throw NetworkException('No internet connection. Please try again.');
    }
    throw ServerException(message);
  }
}
