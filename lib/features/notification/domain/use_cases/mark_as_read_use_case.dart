import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/utils/unit.dart';
import 'package:marikina_market_mobile/features/notification/domain/repositories/notification_repository.dart';

class MarkAsReadUseCase {
  final NotificationRepository _repository;
  MarkAsReadUseCase(this._repository);

  Future<Result<Unit>> call(int id) async => await _repository.markAsRead(id);
}
