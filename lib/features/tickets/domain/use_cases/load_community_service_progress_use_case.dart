import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/usecases/usecase.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/community_service_progress.dart';
import 'package:marikina_market_mobile/features/tickets/domain/repositories/ticket_repository.dart';

class LoadCommunityServiceProgressUseCase
    implements UseCase<CommunityServiceProgress, int> {
  final TicketRepository _repository;

  LoadCommunityServiceProgressUseCase(this._repository);

  @override
  Future<Result<CommunityServiceProgress>> call(int ticketId) {
    return _repository.getCommunityServiceProgress(ticketId);
  }
}
