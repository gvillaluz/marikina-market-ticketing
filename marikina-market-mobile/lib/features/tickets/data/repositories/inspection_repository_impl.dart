import 'package:marikina_market_mobile/features/tickets/domain/entities/person_candidate.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/person_ticket_history.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/inspection_verification.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/verify_inspection_input.dart';
import 'package:marikina_market_mobile/core/errors/exceptions.dart';
import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/tickets/data/data_sources/inspection_local_data_source.dart';
import 'package:marikina_market_mobile/features/tickets/data/data_sources/inspection_remote_data_source.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_hive_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/params/save_inspection_params.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/inspection_ticket_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/market_section.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ordinance.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/page_result.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/save_inspection_result.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/vendor_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ordinance_shortcuts.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/warning_ordinance.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/domain/repositories/inspection_repository.dart';

class InspectionRepositoryImpl implements InspectionRepository {
  final InspectionRemoteDataSource remoteDataSource;
  final InspectionLocalDataSource localDataSource;
  InspectionRepositoryImpl(this.remoteDataSource, this.localDataSource);

  @override
  Future<Result<PageResult<InspectionTicketSummary>>> loadInspections(
    String search,
    int offset,
    ViolationType? type,
  ) async {
    try {
      final inspectionModels = await remoteDataSource.loadInspections(
        search,
        offset,
        type,
      );

      return Result.success(inspectionModels.toEntity((m) => m.toEntity()));
    } on ValidationException catch (e) {
      return Result.failure(ValidationFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Result.failure(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<List<Ordinance>>> loadCacheOrdinances() async {
    try {
      final ordinanceModels = await localDataSource.getCacheOrdinances();
      return Result.success(
        ordinanceModels.map((model) => model.toEntity()).toList(),
      );
    } on CacheException catch (e) {
      return Result.failure(CacheFailure(e.message));
    }
  }

  @override
  Future<Result<List<Ordinance>>> loadOrdinances() async {
    try {
      final ordinanceModels = await remoteDataSource.getOrdinances();
      await localDataSource.saveOrdinances(
        ordinanceModels.map(OrdinanceHiveModel.fromModel).toList(),
      );
      return Result.success(
        ordinanceModels.map((model) => model.toEntity()).toList(),
      );
    } on CacheException catch (e) {
      return Result.failure(CacheFailure(e.message));
    } on NetworkException catch (e) {
      final cached = await loadCacheOrdinances();
      if (cached is Success<List<Ordinance>> && cached.data.isEmpty) {
        return Result.failure(NetworkFailure(e.message));
      }
      return cached;
    } on UnauthorizedException catch (e) {
      return Result.failure(UnauthorizedFailure(e.message));
    } on ValidationException catch (e) {
      return Result.failure(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message));
    }
  }

  // Only switched-on sections can be chosen for an unregistered vendor.
  @override
  Future<Result<List<MarketSection>>> getMarketSections() => _personResult(
    () async => (await remoteDataSource.getMarketSections())
        .where((section) => section.isActive)
        .map((section) => section.toEntity())
        .toList(),
  );

  @override
  Future<Result<PageResult<VendorSummary>>> searchBusinesses(String search) =>
      _personResult(
        () async => (await remoteDataSource.searchBusinesses(
          search,
        )).toEntity((m) => m.toEntity()),
      );

  @override
  Future<Result<List<PersonCandidate>>> getBusinessPeople(int businessId) =>
      _personResult(
        () async => (await remoteDataSource.getBusinessPeople(
          businessId,
        )).map((m) => m.toEntity()).toList(),
      );

  @override
  Future<Result<PersonCandidate?>> getOwnerPerson(int businessId) =>
      _personResult(
        () async =>
            (await remoteDataSource.getOwnerPerson(businessId))?.toEntity(),
      );

  @override
  Future<Result<PersonCandidate>> addOwnerPerson(int businessId) =>
      _personResult(
        () async =>
            (await remoteDataSource.addOwnerPerson(businessId)).toEntity(),
      );

  @override
  Future<Result<OrdinanceShortcuts>> getOrdinanceShortcuts(int? personId) =>
      _personResult(
        () async =>
            (await remoteDataSource.getOrdinanceShortcuts(personId)).toEntity(),
      );

  @override
  Future<Result<FineSummary>> getTicketFineSummary(
    List<int> ordinanceIds,
    int? vendorId, {
    int? personId,
  }) async {
    try {
      final fineModels = await remoteDataSource.getFineSummary(
        ordinanceIds,
        vendorId,
        personId: personId,
      );

      return Result.success(fineModels.toEntity());
    } on ValidationException catch (e) {
      return Result.failure(ValidationFailure(e.message));
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<List<WarningOrdinance>>> checkWarningOrdinances(
    List<int> ordinanceIds,
    int? vendorId, {
    int? personId,
  }) async {
    try {
      final warningModels = await remoteDataSource.checkWarningOrdinances(
        ordinanceIds,
        vendorId,
        personId: personId,
      );
      return Result.success(
        warningModels.map((model) => model.toEntity()).toList(),
      );
    } on ValidationException catch (e) {
      return Result.failure(ValidationFailure(e.message));
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<SaveInspectionResult>> saveNewInspection(
    SaveInspectionParams params,
  ) async {
    try {
      final resultModel = await remoteDataSource.saveInspection(params);

      return Result.success(resultModel.toEntity());
    } on ConflictException catch (e) {
      return Result.failure(
        ConflictFailure(
          e.droppedOrdinances.map((model) => model.toEntity()).toList(),
          e.message,
        ),
      );
    } on DuplicateWarningException catch (e) {
      return Result.failure(DuplicateWarningFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Result.failure(UnauthorizedFailure(e.message));
    } on ValidationException catch (e) {
      return Result.failure(ValidationFailure(e.message));
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message));
    }
  }

  Future<Result<T>> _personResult<T>(Future<T> Function() request) async {
    try {
      return Result.success(await request());
    } on ValidationException catch (e) {
      return Result.failure(ValidationFailure(e.message));
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<PageResult<PersonCandidate>>> matchPeople(
    String name,
    int offset,
  ) => _personResult(
    () async => (await remoteDataSource.matchPeople(
      name,
      offset,
    )).toEntity((m) => m.toEntity()),
  );
  @override
  Future<Result<PersonCandidate>> createPerson(
    String name,
    String address,
    String? phone,
  ) => _personResult(
    () async =>
        (await remoteDataSource.createPerson(name, address, phone)).toEntity(),
  );
  @override
  Future<Result<PageResult<PersonTicketHistory>>> getPersonHistory(
    int personId,
    int offset,
  ) => _personResult(
    () async => (await remoteDataSource.getPersonHistory(
      personId,
      offset,
    )).toEntity((m) => m.toEntity()),
  );
  @override
  Future<Result<InspectionVerification>> verifyInspection(
    VerifyInspectionInput input,
  ) => _personResult(
    () async => (await remoteDataSource.verifyInspection(input)).toEntity(),
  );
}
