import 'package:marikina_market_mobile/features/tickets/domain/entities/person_candidate.dart';

import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/page_result.dart';
import 'package:marikina_market_mobile/features/tickets/domain/repositories/inspection_repository.dart';

class MatchPeopleUseCase {
  final InspectionRepository _repository;
  const MatchPeopleUseCase(this._repository);
  Future<Result<PageResult<PersonCandidate>>> call(
    String name,
    String? address,
    String? phone,
    int offset,
  ) => _repository.matchPeople(name, address, phone, offset);
}
