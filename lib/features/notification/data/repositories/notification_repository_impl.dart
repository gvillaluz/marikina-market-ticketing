import 'package:marikina_market_mobile/core/errors/exceptions.dart';
import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/page_result.dart';
import 'package:marikina_market_mobile/core/utils/unit.dart';
import 'package:marikina_market_mobile/features/notification/data/data_sources/notification_remote_data_source.dart';
import 'package:marikina_market_mobile/features/notification/domain/entities/notification_summary.dart';
import 'package:marikina_market_mobile/features/notification/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;
  NotificationRepositoryImpl(this.remoteDataSource);

  @override
  Future<Result<int>> loadUnreadCount() async {
    try {
      return Result.success(await remoteDataSource.getUnreadCount());
    } on UnauthorizedException catch (e) {
      return Result.failure(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } on FormatException {
      return Result.failure(
        ServerFailure('Unable to load the unread count. Please refresh.'),
      );
    } on TypeError {
      return Result.failure(
        ServerFailure('Unable to load the unread count. Please refresh.'),
      );
    }
  }

  @override
  Future<Result<PageResult<NotificationSummary>>> loadNotifications(
    int offset,
    String filter,
  ) async {
    try {
      final notificationSummaries = await remoteDataSource.getNotifications(
        offset,
        filter,
      );
      return Result.success(
        notificationSummaries.toEntity((m) => m.toEntity()),
      );
    } on UnauthorizedException catch (e) {
      return Result.failure(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } on FormatException {
      return Result.failure(
        ServerFailure('Unable to read notifications. Please try again.'),
      );
    } on TypeError {
      return Result.failure(
        ServerFailure('Unable to read notifications. Please try again.'),
      );
    } on ArgumentError {
      return Result.failure(
        ServerFailure('Unable to read notifications. Please try again.'),
      );
    }
  }

  @override
  Future<Result<Unit>> markAsRead(int id) async {
    try {
      await remoteDataSource.markAsRead(id);
      return Result.success(unit);
    } on UnauthorizedException catch (e) {
      return Result.failure(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message));
    }
  }
}
