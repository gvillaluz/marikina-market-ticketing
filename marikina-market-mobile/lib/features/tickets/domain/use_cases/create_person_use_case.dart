import 'package:marikina_market_mobile/features/tickets/domain/entities/person_candidate.dart';

import 'package:marikina_market_mobile/core/errors/result.dart';

import 'package:marikina_market_mobile/features/tickets/domain/repositories/inspection_repository.dart';

class CreatePersonUseCase {
  final InspectionRepository _repository;
  const CreatePersonUseCase(this._repository);
  Future<Result<PersonCandidate>> call(
    String name,
    String address,
    String? phone,
  ) => _repository.createPerson(name, address, phone);
}
