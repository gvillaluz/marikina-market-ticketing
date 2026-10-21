import 'package:dio/dio.dart';
import 'package:marikina_market_mobile/core/errors/api_error_message.dart';
import 'package:marikina_market_mobile/features/auth/domain/enums/role.dart';
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
  Future<int> getUnreadCount();
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final ApiClient apiClient;
  final Role role;

  NotificationRemoteDataSourceImpl(
    this.apiClient, {
    this.role = Role.marketEnforcer,
  });

  String get _path => switch (role) {
    Role.marketVendor => '/notification/vendor',
    Role.marketEnforcer => '/notification',
    _ => throw UnauthorizedException(
      'This account cannot access mobile notifications.',
    ),
  };

  Never _handleError(DioException e) {
    final message = ApiErrorMessage.fromBody(e.response?.data);
    if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
      throw UnauthorizedException(
        message ?? 'Please sign in with an authorized account.',
      );
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      throw NetworkException(
        message ?? 'No internet connection. Please try again.',
      );
    }
    throw ServerException(
      message ?? 'Unable to update notifications. Please try again.',
    );
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final response = await apiClient.get(
        _path,
        queryParameters: {'offset': 0, 'filter': 'Unread'},
      );
      final data = response.data;
      if (data is! Map<String, Object?> ||
          data['total'] is! int ||
          (data['total'] as int) < 0) {
        throw const FormatException('Invalid unread count.');
      }
      return data['total'] as int;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<PageResultModel<NotificationSummaryModel>> getNotifications(
    int offset,
    String filter,
  ) async {
    try {
      final response = await apiClient.get(
        _path,
        queryParameters: {'offset': offset, 'filter': filter},
      );

      final data = response.data;

      if (data == null) return PageResultModel(items: [], hasMore: false);

      return PageResultModel.fromJson(
        data,
        (json) => NotificationSummaryModel.fromJson(json),
      );
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<void> markAsRead(int id) async {
    try {
      await apiClient.patch('$_path/$id/read');
    } on DioException catch (e) {
      _handleError(e);
    }
  }
}
