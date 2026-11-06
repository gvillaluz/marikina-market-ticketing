import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/person_candidate.dart';
import 'package:marikina_market_mobile/features/tickets/domain/repositories/inspection_repository.dart';

class GetBusinessPeopleUseCase {
  final InspectionRepository _repository;
  const GetBusinessPeopleUseCase(this._repository);
  Future<Result<List<PersonCandidate>>> call(int businessId) =>
      _repository.getBusinessPeople(businessId);
}
