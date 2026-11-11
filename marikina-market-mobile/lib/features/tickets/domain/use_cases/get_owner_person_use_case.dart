import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/person_candidate.dart';
import 'package:marikina_market_mobile/features/tickets/domain/repositories/inspection_repository.dart';

class GetOwnerPersonUseCase {
  final InspectionRepository _repository;
  const GetOwnerPersonUseCase(this._repository);
  Future<Result<PersonCandidate?>> call(int businessId) =>
      _repository.getOwnerPerson(businessId);
}
