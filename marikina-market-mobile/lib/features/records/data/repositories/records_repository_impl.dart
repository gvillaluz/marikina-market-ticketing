import 'package:dio/dio.dart';
import 'package:marikina_market_mobile/core/errors/exceptions.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/ticket_receipt_proof.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/community_service_progress.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/core/errors/api_error_message.dart';
import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import '../../domain/entities/records_page_data.dart';
import '../../domain/entities/vendor_ticket_detail.dart';
import '../../domain/enums/records_filter.dart';
import '../../domain/repositories/records_repository.dart';
import '../data_sources/records_remote_data_source.dart';

class RecordsRepositoryImpl implements RecordsRepository {
  final RecordsRemoteDataSource remote;
  const RecordsRepositoryImpl(this.remote);
  @override
  Future<Result<TicketReceiptProof>> loadReceipt(int ticketId) =>
      _settlementResult(() async {
        _validateId(ticketId);
        final receipt = (await remote.loadReceipt(ticketId)).toEntity();
        _validateReceipt(receipt, ticketId);
        return receipt;
      });
  @override
  Future<Result<CommunityServiceProgress>> loadServiceProgress(int ticketId) =>
      _settlementResult(() async {
        _validateId(ticketId);
        final progress = (await remote.loadServiceProgress(
          ticketId,
        )).toEntity();
        if (progress.ticketId != ticketId ||
            progress.hoursRequired <= 0 ||
            !progress.hoursCompleted.isFinite ||
            progress.hoursCompleted < 0 ||
            !progress.hoursRemaining.isFinite ||
            progress.hoursRemaining < 0 ||
            !progress.completionPercentage.isFinite ||
            progress.completionPercentage < 0 ||
            progress.entries.any(
              (entry) => !entry.hoursWorked.isFinite || entry.hoursWorked <= 0,
            )) {
          throw const FormatException('Invalid community-service response.');
        }
        return progress;
      });
  void _validateId(int id) {
    if (id <= 0 || id > 2147483647) {
      throw ValidationException('Invalid ticket ID.');
    }
  }

  void _validateReceipt(TicketReceiptProof receipt, int id) {
    if (receipt.ticketId != id ||
        (receipt.penaltyType != PenaltyType.cashFine &&
            receipt.penaltyType != PenaltyType.bloodDonation)) {
      throw const FormatException('Invalid settlement receipt response.');
    }
  }

  Future<Result<T>> _settlementResult<T>(Future<T> Function() request) async {
    try {
      return Success(await request());
    } on DioException catch (error) {
      return ResultFailure(_failure(error));
    } on ValidationException catch (error) {
      return ResultFailure(ValidationFailure(error.message));
    } on FormatException {
      return const ResultFailure(
        ServerFailure('Unable to read settlement details. Please try again.'),
      );
    } on TypeError {
      return const ResultFailure(
        ServerFailure('Unable to read settlement details. Please try again.'),
      );
    } on ArgumentError {
      return const ResultFailure(
        ServerFailure('Unable to read settlement details. Please try again.'),
      );
    }
  }

  @override
  Future<Result<RecordsPageData>> loadRecords({
    required String search,
    required int offset,
    required RecordsFilter filter,
  }) async {
    if (offset < 0 || search.length > 200) {
      return const ResultFailure(
        ValidationFailure(
          'Search must be at most 200 characters and offset must not be negative.',
        ),
      );
    }
    try {
      return Success(
        (await remote.loadRecords(search.trim(), offset, filter)).toEntity(),
      );
    } on DioException catch (error) {
      return ResultFailure(_failure(error));
    } on FormatException {
      return const ResultFailure(
        ServerFailure('Unable to read your records. Please try again.'),
      );
    } on TypeError {
      return const ResultFailure(
        ServerFailure('Unable to read your records. Please try again.'),
      );
    } on ArgumentError {
      return const ResultFailure(
        ServerFailure('Unable to read your records. Please try again.'),
      );
    }
  }

  @override
  Future<Result<VendorTicketDetail>> loadDetail(int ticketId) async {
    if (ticketId <= 0 || ticketId > 2147483647) {
      return const ResultFailure(ValidationFailure('Invalid ticket ID.'));
    }
    try {
      return Success((await remote.loadDetail(ticketId)).toEntity());
    } on DioException catch (error) {
      return ResultFailure(_failure(error));
    } on FormatException {
      return const ResultFailure(
        ServerFailure('Unable to read this record. Please try again.'),
      );
    } on TypeError {
      return const ResultFailure(
        ServerFailure('Unable to read this record. Please try again.'),
      );
    } on ArgumentError {
      return const ResultFailure(
        ServerFailure('Unable to read this record. Please try again.'),
      );
    }
  }

  Failure _failure(DioException error) {
    final serverMessage = ApiErrorMessage.fromBody(error.response?.data);
    final body = error.response?.data;
    final plainMessage =
        error.response?.statusCode == 401 &&
            body is String &&
            body.trim() == 'Invalid token.'
        ? body
        : null;
    final message = serverMessage ?? plainMessage;
    final status = error.response?.statusCode;
    if (status == 401 || status == 403) {
      return UnauthorizedFailure(
        message ??
            (status == 401
                ? 'Your session has expired. Please sign in again.'
                : 'You do not have access to these records.'),
      );
    }
    if (status == 400) {
      return ValidationFailure(
        message ?? 'Please check your search or ticket ID.',
      );
    }
    if (status == 404) return ServerFailure(message ?? 'Ticket not found.');
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return NetworkFailure(
        message ??
            'Unable to connect. Please check your connection and try again.',
      );
    }
    return ServerFailure(
      message ?? 'Unable to load your records. Please try again.',
    );
  }
}
