import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/notification/domain/repositories/notification_repository.dart';

class LoadUnreadCountUseCase {
  final NotificationRepository _repository;
  LoadUnreadCountUseCase(this._repository);
  Future<Result<int>> call() => _repository.loadUnreadCount();
}
