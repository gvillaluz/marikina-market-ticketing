import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/page_result.dart';
import 'package:marikina_market_mobile/core/utils/unit.dart';
import 'package:marikina_market_mobile/features/notification/domain/entities/notification_summary.dart';

abstract class NotificationRepository {
  Future<Result<PageResult<NotificationSummary>>> loadNotifications(
    int offset,
    String filter,
  );

  Future<Result<Unit>> markAsRead(int id);
}
