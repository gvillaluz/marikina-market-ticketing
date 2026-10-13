import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/page_result.dart';
import 'package:marikina_market_mobile/features/notification/domain/entities/notification_summary.dart';
import 'package:marikina_market_mobile/features/notification/domain/repositories/notification_repository.dart';

class LoadNotificationsUseCase {
  final NotificationRepository _repository;
  LoadNotificationsUseCase(this._repository);

  Future<Result<PageResult<NotificationSummary>>> call(
    int offset,
    String filter,
  ) async => await _repository.loadNotifications(offset, filter);
}
