import 'dart:io';

import 'package:marikina_market_mobile/core/errors/exceptions.dart';
import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/tickets/data/data_sources/ticket_remote_data_source.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/page_result.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/community_service_progress.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/submit_community_service_log_params.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_detail.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/ticket_receipt_proof.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_summary.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/features/tickets/domain/repositories/ticket_repository.dart';

class TicketRepositoryImpl implements TicketRepository {
  final TicketRemoteDataSource remoteDataSource;
  TicketRepositoryImpl(this.remoteDataSource);

  Result<T> _failure<T>(Exception error) {
    return switch (error) {
      ValidationException(:final message) => Result.failure(
        ValidationFailure(message),
      ),
      UnauthorizedException(:final message) => Result.failure(
        UnauthorizedFailure(message),
      ),
      NotFoundException(:final message) => Result.failure(
        ValidationFailure(message),
      ),
      NetworkException(:final message) => Result.failure(
        NetworkFailure(message),
      ),
      ServerException(:final message) => Result.failure(ServerFailure(message)),
      _ => throw error,
    };
  }

  @override
  Future<Result<TicketDetail>> getTicketDetail(int ticketId) async {
    try {
      final ticketModel = await remoteDataSource.getTicketDetailById(ticketId);
      return Result.success(ticketModel.toEntity());
    } on Exception catch (error) {
      return _failure(error);
    }
  }

  @override
  Future<Result<PageResult<TicketSummary>>> loadTickets(
    String search,
    int offset,
    TicketStatus status,
  ) async {
    try {
      final ticketModels = await remoteDataSource.loadTickets(
        search,
        offset,
        status,
      );

      return Result.success(ticketModels.toEntity((m) => m.toEntity()));
    } on Exception catch (error) {
      return _failure(error);
    }
  }

  @override
  Future<Result<TicketReceiptProof>> getTicketReceiptProof(int ticketId) async {
    try {
      final model = await remoteDataSource.getTicketReceiptProof(ticketId);
      return Result.success(model.toEntity());
    } on Exception catch (error) {
      return _failure(error);
    }
  }

  @override
  Future<Result<CommunityServiceProgress>> getCommunityServiceProgress(
    int ticketId,
  ) async {
    try {
      final model = await remoteDataSource.getCommunityServiceProgress(
        ticketId,
      );
      return Result.success(model.toEntity());
    } on Exception catch (error) {
      return _failure(error);
    }
  }

  @override
  Future<Result<TicketReceiptProof>> submitTicketReceiptProof(
    int ticketId,
    File proofFile,
  ) async {
    try {
      final model = await remoteDataSource.submitTicketReceiptProof(
        ticketId,
        proofFile,
      );
      return Result.success(model.toEntity());
    } on Exception catch (error) {
      return _failure(error);
    }
  }

  @override
  Future<Result<CommunityServiceProgress>> submitCommunityServiceLog(
    SubmitCommunityServiceLogParams params,
  ) async {
    try {
      final model = await remoteDataSource.submitCommunityServiceLog(params);
      return Result.success(model.toEntity());
    } on Exception catch (error) {
      return _failure(error);
    }
  }
}
