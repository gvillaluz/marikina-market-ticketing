import 'dart:io';

import 'package:dio/dio.dart';
import 'package:marikina_market_mobile/core/errors/exceptions.dart';
import 'package:marikina_market_mobile/core/network/client.dart';
import 'package:marikina_market_mobile/core/utils/file_compressor_util.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/duplicate_info_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/fine_summary_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/inspection_summary_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_model.dart';
import 'package:marikina_market_mobile/core/shared/data/models/page_result_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/params/save_inspection_params.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/save_inspection_result_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/vendor_summary_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/warning_ordinance_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';

abstract class InspectionRemoteDataSource {
  Future<PageResultModel<InspectionSummaryModel>> loadInspections(
    String search,
    int offset,
    ViolationType type,
  );
  Future<List<OrdinanceModel>> getOrdinances();
  Future<VendorSummaryModel> getVendorByCode(String codeValue);
  Future<List<VendorSummaryModel>> getVendorByStall(String stallNumber);
  Future<FineSummaryModel> getFineSummary(List<int> ordinanceIds, int vendorId);
  Future<List<WarningOrdinanceModel>> checkWarningOrdinances(
    List<int> ordinanceIds,
    int vendorId,
  );
  Future<SaveInspectionResultModel> saveInspection(SaveInspectionParams params);
}

class InspectionRemoteDataSourceImpl implements InspectionRemoteDataSource {
  final ApiClient apiClient;

  InspectionRemoteDataSourceImpl(this.apiClient);

  @override
  Future<PageResultModel<InspectionSummaryModel>> loadInspections(
    String search,
    int offset,
    ViolationType type,
  ) async {
    try {
      String query =
          '/enforcer/tickets/inspections?offset=$offset&type=${type.value}';

      if (search.isNotEmpty) {
        query = '$query&search=$search';
      }

      final response = await apiClient.get(query);

      final data = response.data;

      if (data == null) return PageResultModel(items: [], hasMore: false);

      return PageResultModel.fromJson(
        data,
        (json) => InspectionSummaryModel.fromJson(json),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw ValidationException(e.response?.data['message'] ?? '');
      }

      if (e.response?.statusCode == 400) {
        throw UnauthorizedException(
          e.response?.data['message'] ?? 'Unauthorized.',
        );
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('No internet connection. Please try again.');
      }

      throw ServerException('Something went wrong. Please try again later');
    }
  }

  @override
  Future<VendorSummaryModel> getVendorByCode(String codeValue) async {
    try {
      final response = await apiClient.get('/vendor/code/$codeValue');

      return VendorSummaryModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw ValidationException(
          e.response?.data['message'] ?? 'Invalid QR Code',
        );
      }

      if (e.response?.statusCode == 400) {
        throw ValidationException(
          e.response?.data['message'] ?? 'Invalid QR Code.',
        );
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('No internet connection. Please try again.');
      }

      throw ServerException('Something went wrong. Please try again later');
    }
  }

  @override
  Future<List<VendorSummaryModel>> getVendorByStall(String stallNumber) async {
    try {
      final response = await apiClient.get('/vendor/stall/$stallNumber');

      final List<dynamic> data = response.data;

      if (data.isEmpty) {
        return [];
      }

      return data.map((json) => VendorSummaryModel.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw ValidationException(
          e.response?.data['message'] ?? 'Invalid stall number',
        );
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('No internet connection. Please try again.');
      }

      throw ServerException('Something went wrong. Please try again later');
    }
  }

  @override
  Future<List<OrdinanceModel>> getOrdinances() async {
    try {
      final response = await apiClient.get('/ordinance');

      final List<dynamic> data = response.data;

      return data
          .map((ordinance) => OrdinanceModel.fromJson(ordinance))
          .toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('No internet connection. Please try again.');
      }

      throw ServerException('Something went wrong. Please try again later');
    }
  }

  @override
  Future<FineSummaryModel> getFineSummary(
    List<int> ordinanceIds,
    int vendorId,
  ) async {
    try {
      final response = await apiClient.post(
        '/enforcer/tickets/fine-summary',
        data: {"ordinance_ids": ordinanceIds, "vendor_id": vendorId},
      );

      return FineSummaryModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw ValidationException(
          e.response?.data['message'] ?? 'Invalid stall number',
        );
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('No internet connection. Please try again.');
      }

      throw ServerException('Something went wrong. Please try again later');
    }
  }

  @override
  Future<List<WarningOrdinanceModel>> checkWarningOrdinances(
    List<int> ordinanceIds,
    int vendorId,
  ) async {
    try {
      final response = await apiClient.post(
        '/enforcer/tickets/warning-check',
        data: {'ordinance_ids': ordinanceIds, 'vendor_id': vendorId},
      );
      final data = response.data as List<dynamic>;
      return data
          .map(
            (item) =>
                WarningOrdinanceModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw ValidationException(
          e.response?.data['message'] ?? 'Unable to check warning ordinances.',
        );
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('No internet connection. Please try again.');
      }
      throw ServerException('Something went wrong. Please try again later');
    }
  }

  @override
  Future<SaveInspectionResultModel> saveInspection(
    SaveInspectionParams params,
  ) async {
    try {
      List<MultipartFile> evidenceFiles = [];
      if (params.evidences != null && params.evidences!.isNotEmpty) {
        for (var file in params.evidences!) {
          final compressedFile = await compressImage(File(file.path));

          evidenceFiles.add(
            await MultipartFile.fromFile(
              compressedFile.path,
              filename: file.name,
            ),
          );
        }
      }

      final formData = FormData.fromMap({
        "vendor_id": params.vendorId,
        "market_section_id": params.marketSectionId,
        "enforcer_id": params.enforcerId,
        "type": params.ticketType.value,
        "description": params.description,
        "penalty_type": params.penaltyType.value,
        "community_service_hours": params.communityServiceHours,
        "ordinances": params.ordinanceIds,
        "ticket_evidence_files": evidenceFiles,
      }, ListFormat.multi);

      final response = await apiClient.post(
        '/enforcer/tickets/new-inspection',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data; boundary=${formData.boundary}',
        ),
      );

      return SaveInspectionResultModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final title = e.response?.data['title'] as String?;

        if (title == 'Duplicate Ordinances Today') {
          final duplicates =
              (e.response?.data['duplicateOrdinances'] as List<dynamic>? ?? [])
                  .map(
                    (json) => DuplicateInfoModel.fromJson(
                      json as Map<String, dynamic>,
                    ),
                  )
                  .toList();

          throw ConflictException(
            e.response?.data['message'] as String? ??
                'This request conflicts with existing active tickets today.',
            duplicates,
          );
        }

        if (title == 'Duplicate Warning') {
          throw DuplicateWarningException(
            e.response?.data['message'] ??
                'This vendor already has an active warning ticket.',
          );
        }
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('No internet connection. Please try again.');
      }

      throw ServerException('Something went wrong. Please try again later');
    }
  }
}
