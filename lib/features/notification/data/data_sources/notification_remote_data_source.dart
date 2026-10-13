import 'package:dio/dio.dart';
import 'package:marikina_market_mobile/core/errors/exceptions.dart';
import 'package:marikina_market_mobile/core/network/client.dart';
import 'package:marikina_market_mobile/core/shared/data/models/page_result_model.dart';
import 'package:marikina_market_mobile/features/notification/data/models/notification_summary_model.dart';

abstract class NotificationRemoteDataSource {
  Future<PageResultModel<NotificationSummaryModel>> getNotifications(
    int offset,
    String filter,
  );
  Future<void> markAsRead(int id);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final ApiClient apiClient;

  NotificationRemoteDataSourceImpl(this.apiClient);

  @override
  Future<PageResultModel<NotificationSummaryModel>> getNotifications(
    int offset,
    String filter,
  ) async {
    try {
      final response = await apiClient.get(
        '/notification',
        queryParameters: {'offset': offset, 'filter': filter},
      );

      final data = response.data;

      if (data == null) return PageResultModel(items: [], hasMore: false);

      return PageResultModel.fromJson(
        data,
        (json) => NotificationSummaryModel.fromJson(json),
      );
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
  Future<void> markAsRead(int id) async {
    try {
      await apiClient.patch('/notification/$id/read');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('No internet connection. Please try again.');
      }

      throw ServerException('Something went wrong. Please try again later');
    }
  }
}
