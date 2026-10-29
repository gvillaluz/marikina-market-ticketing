import 'package:marikina_market_mobile/features/tickets/domain/entities/person_ticket_history.dart';

import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/page_result.dart';
import 'package:marikina_market_mobile/features/tickets/domain/repositories/inspection_repository.dart';

class GetPersonHistoryUseCase {
  final InspectionRepository _repository;
  const GetPersonHistoryUseCase(this._repository);
  Future<Result<PageResult<PersonTicketHistory>>> call(
    int personId,
    int offset,
  ) => _repository.getPersonHistory(personId, offset);
}
