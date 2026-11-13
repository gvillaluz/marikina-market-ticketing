import 'package:marikina_market_mobile/features/tickets/data/models/person_candidate_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/person_ticket_history_model.dart';
import 'dart:io';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:marikina_market_mobile/core/errors/exceptions.dart';
import 'package:marikina_market_mobile/core/network/client.dart';
import 'package:marikina_market_mobile/core/utils/file_compressor_util.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/duplicate_info_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/fine_summary_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/inspection_summary_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/market_section_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_model.dart';
import 'package:marikina_market_mobile/core/shared/data/models/page_result_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/params/save_inspection_params.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_shortcuts_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/save_inspection_result_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/vendor_summary_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/warning_ordinance_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';

abstract class InspectionRemoteDataSource {
  Future<PageResultModel<PersonCandidateModel>> matchPeople(
    String name,
    int offset,
  );
  Future<PersonCandidateModel> createPerson(
    String name,
    String address,
    String? phone,
  );
  Future<PageResultModel<PersonTicketHistoryModel>> getPersonHistory(
    int personId,
    int offset,
  );

  Future<PageResultModel<InspectionSummaryModel>> loadInspections(
    String search,
    int offset,
    ViolationType? type,
  );
  Future<List<OrdinanceModel>> getOrdinances();
  Future<List<MarketSectionModel>> getMarketSections();
  Future<PageResultModel<VendorSummaryModel>> searchBusinesses(String search);
  Future<List<PersonCandidateModel>> getBusinessPeople(int businessId);
  // Null when the owner has no person record yet.
  Future<PersonCandidateModel?> getOwnerPerson(int businessId);
  Future<PersonCandidateModel> addOwnerPerson(int businessId);
  Future<OrdinanceShortcutsModel> getOrdinanceShortcuts(int? personId);
  Future<FineSummaryModel> getFineSummary(
    List<int> ordinanceIds,
    int? vendorId, {
    int? personId,
  });
  Future<List<WarningOrdinanceModel>> checkWarningOrdinances(
    List<int> ordinanceIds,
    int? vendorId, {
    int? personId,
  });
  Future<SaveInspectionResultModel> saveInspection(SaveInspectionParams params);
}

class InspectionRemoteDataSourceImpl implements InspectionRemoteDataSource {
  final ApiClient apiClient;

  InspectionRemoteDataSourceImpl(this.apiClient);

  @override
  Future<PageResultModel<InspectionSummaryModel>> loadInspections(
    String search,
    int offset,
    ViolationType? type,
  ) async {
    try {
      final response = await apiClient.get(
        '/enforcer/tickets/inspections',
        queryParameters: <String, Object?>{
          'offset': offset,
          if (type != null) 'type': type.value,
          if (search.isNotEmpty) 'search': search,
        },
      );

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
  Future<List<MarketSectionModel>> getMarketSections() =>
      _businessRequest(() async {
        final response = await apiClient.get('/marketsection');
        return (response.data as List<Object?>)
            .map(
              (json) =>
                  MarketSectionModel.fromJson(json as Map<String, Object?>),
            )
            .toList();
      });

  @override
  Future<PageResultModel<VendorSummaryModel>> searchBusinesses(String search) =>
      _businessRequest(() async {
        final response = await apiClient.get(
          '/vendor/lookup',
          queryParameters: {'search': search},
        );
        return PageResultModel.fromJson(
          response.data,
          VendorSummaryModel.fromJson,
        );
      });

  @override
  Future<List<PersonCandidateModel>> getBusinessPeople(int businessId) =>
      _businessRequest(() async {
        final response = await apiClient.get('/vendor/$businessId/people');
        return (response.data as List<Object?>)
            .map(
              (json) =>
                  PersonCandidateModel.fromJson(json as Map<String, Object?>),
            )
            .toList();
      });

  @override
  Future<PersonCandidateModel?> getOwnerPerson(
    int businessId,
  ) => _businessRequest(() async {
    final response = await apiClient.get('/vendor/$businessId/owner-person');
    if (response.statusCode == 204) return null;
    return PersonCandidateModel.fromJson(response.data as Map<String, Object?>);
  });

  // The server builds the person from the business record and returns the
  // existing one if it is already there, so a retry never makes a duplicate.
  @override
  Future<PersonCandidateModel> addOwnerPerson(
    int businessId,
  ) => _businessRequest(() async {
    final response = await apiClient.post('/vendor/$businessId/owner-person');
    return PersonCandidateModel.fromJson(response.data as Map<String, Object?>);
  });

  @override
  Future<OrdinanceShortcutsModel> getOrdinanceShortcuts(int? personId) =>
      _businessRequest(() async {
        final response = await apiClient.get(
          '/ordinance/shortcuts',
          queryParameters: {'person_id': ?personId},
        );
        return OrdinanceShortcutsModel.fromJson(
          response.data as Map<String, Object?>,
        );
      });

  Future<T> _businessRequest<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 400 || status == 404) {
        throw ValidationException(_personError(e));
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
    int? vendorId, {
    int? personId,
  }) async {
    try {
      final response = await apiClient.post(
        '/enforcer/tickets/fine-summary',
        data: {
          "ordinance_ids": ordinanceIds,
          "vendor_id": vendorId,
          "person_id": personId,
        },
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
    int? vendorId, {
    int? personId,
  }) async {
    try {
      final response = await apiClient.post(
        '/enforcer/tickets/warning-check',
        data: {
          'ordinance_ids': ordinanceIds,
          'vendor_id': vendorId,
          'person_id': personId,
        },
      );
      final data = response.data as List<dynamic>;
      return data
          .map(
            (item) =>
                WarningOrdinanceModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 ||
          e.response?.statusCode == 409 ||
          e.response?.statusCode == 404) {
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
              filename: 'supporting-${evidenceFiles.length + 1}.jpg',
              contentType: DioMediaType('image', 'jpeg'),
            ),
          );
        }
      }

      MultipartFile? paperPhoto;
      if (params.paperTicketPhoto != null) {
        final compressed = await compressImage(
          File(params.paperTicketPhoto!.path),
        );
        paperPhoto = await MultipartFile.fromFile(
          compressed.path,
          filename: 'paper-ticket.jpg',
          contentType: DioMediaType('image', 'jpeg'),
        );
      }
      final formData = FormData.fromMap({
        "vendor_id": ?params.vendorId,
        "person_id": params.personId,
        "paper_reference": params.paperReference?.trim(),
        "issue_place": params.issuePlace?.trim(),
        "paper_violator_name": params.paperViolatorName,
        "fine_assessments": jsonEncode(
          params.fineAssessments
              .map(
                (assessment) => {
                  'ordinance_id': assessment.ordinanceId,
                  'assessed_amount': assessment.assessedAmount,
                },
              )
              .toList(),
        ),
        "market_section_id": params.marketSectionId,
        "enforcer_id": params.enforcerId,
        "type": params.ticketType.value,
        "description": params.description,
        "penalty_type": params.penaltyType.value,
        "community_service_hours": params.communityServiceHours,
        "ordinances": params.ordinanceIds,
        if (params.ticketType == ViolationType.ticket)
          "supporting_evidence_files": evidenceFiles,
        if (params.ticketType == ViolationType.warning)
          "ticket_evidence_files": evidenceFiles,
        "paper_ticket_photo": ?paperPhoto,
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
      if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        final message = data is Map<String, Object?> ? data['message'] : null;
        throw ValidationException(
          message is String && message.trim().isNotEmpty
              ? message
              : 'Please check the inspection details and try again.',
        );
      }
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

      if (e.response?.statusCode == 409) {
        throw ValidationException(_personError(e));
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException(
          'Submission could not be confirmed. Check this person’s history before trying again.',
        );
      }
      throw ServerException(
        'Submission could not be confirmed. Check this person’s history before trying again.',
      );
    }
  }

  String _personError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, Object?>) {
      final message = data['message'] ?? data['detail'];
      if (message is String && message.isNotEmpty) return message;
    }
    return 'Unable to complete this request. Review the details and try again.';
  }

  Future<T> _personRequest<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      if (e.response != null) throw ValidationException(_personError(e));
      throw NetworkException(
        'Request could not be confirmed. Check records before trying again.',
      );
    }
  }

  @override
  Future<PageResultModel<PersonCandidateModel>> matchPeople(
    String name,
    int offset,
  ) => _personRequest(() async {
    final response = await apiClient.post(
      '/persons/matches',
      data: {'name': name, 'offset': offset},
    );
    return PageResultModel.fromJson(
      response.data,
      PersonCandidateModel.fromJson,
    );
  });
  @override
  Future<PersonCandidateModel> createPerson(
    String name,
    String address,
    String? phone,
  ) => _personRequest(() async {
    final response = await apiClient.post(
      '/persons',
      data: {'full_name': name, 'address': address, 'phone_number': phone},
    );
    return PersonCandidateModel.fromJson(response.data);
  });
  @override
  Future<PageResultModel<PersonTicketHistoryModel>> getPersonHistory(
    int personId,
    int offset,
  ) => _personRequest(() async {
    final response = await apiClient.get(
      '/persons/$personId/tickets',
      queryParameters: {'offset': offset},
    );
    return PageResultModel.fromJson(
      response.data,
      PersonTicketHistoryModel.fromJson,
    );
  });
}
