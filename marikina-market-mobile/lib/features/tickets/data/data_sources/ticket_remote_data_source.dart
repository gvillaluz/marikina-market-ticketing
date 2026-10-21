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
    TicketStatus status,
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

  TicketRemoteDataSourceImpl(this.apiClient);

  @override
  Future<PageResultModel<TicketSummaryModel>> loadTickets(
    String search,
    int offset,
    TicketStatus status,
  ) async {
    try {
      var query = '/enforcer/tickets?offset=$offset&status=${status.value}';
      if (search.isNotEmpty) {
        query = '$query&search=$search';
      }

      final response = await apiClient.get(query);
      final data = response.data;
      if (data == null) return PageResultModel(items: [], hasMore: false);

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
      return TicketReceiptProofModel.fromJson(
        response.data as Map<String, dynamic>,
      );
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
      return CommunityServiceProgressModel.fromJson(
        response.data as Map<String, dynamic>,
      );
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
      });
      final response = await apiClient.post(
        '/enforcer/tickets/$ticketId/settlement/receipt',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data; boundary=${formData.boundary}',
        ),
      );
      return TicketReceiptProofModel.fromJson(
        response.data as Map<String, dynamic>,
      );
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
      });
      final response = await apiClient.post(
        '/enforcer/tickets/${params.ticketId}/settlement/community-service',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data; boundary=${formData.boundary}',
        ),
      );
      return CommunityServiceProgressModel.fromJson(
        response.data as Map<String, dynamic>,
      );
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
