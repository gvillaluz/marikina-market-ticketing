import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/person_candidate.dart';
import 'package:marikina_market_mobile/features/tickets/domain/repositories/inspection_repository.dart';

class AddOwnerPersonUseCase {
  final InspectionRepository _repository;
  const AddOwnerPersonUseCase(this._repository);
  Future<Result<PersonCandidate>> call(int businessId) =>
      _repository.addOwnerPerson(businessId);
}
