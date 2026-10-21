import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/usecases/usecase.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/community_service_progress.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/submit_community_service_log_params.dart';
import 'package:marikina_market_mobile/features/tickets/domain/repositories/ticket_repository.dart';

class SubmitCommunityServiceLogUseCase
    implements
        UseCase<CommunityServiceProgress, SubmitCommunityServiceLogParams> {
  final TicketRepository _repository;

  SubmitCommunityServiceLogUseCase(this._repository);

  @override
  Future<Result<CommunityServiceProgress>> call(
    SubmitCommunityServiceLogParams params,
  ) {
    if (params.hoursWorked <= 0) {
      return Future.value(
        Result.failure(
          ValidationFailure('Hours worked must be greater than zero.'),
        ),
      );
    }
    if (!params.proofFile.existsSync()) {
      return Future.value(
        Result.failure(ValidationFailure('Proof documentation is required.')),
      );
    }
    if (params.serviceDate.isAfter(DateTime.now())) {
      return Future.value(
        Result.failure(
          ValidationFailure('Service date cannot be in the future.'),
        ),
      );
    }
    return _repository.submitCommunityServiceLog(params);
  }
}
