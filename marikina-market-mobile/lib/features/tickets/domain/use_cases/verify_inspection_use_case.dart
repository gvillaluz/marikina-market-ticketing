import 'package:marikina_market_mobile/features/tickets/domain/entities/inspection_verification.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/verify_inspection_input.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';

import 'package:marikina_market_mobile/features/tickets/domain/repositories/inspection_repository.dart';

class VerifyInspectionUseCase {
  final InspectionRepository _repository;
  const VerifyInspectionUseCase(this._repository);
  Future<Result<InspectionVerification>> call(VerifyInspectionInput input) =>
      _repository.verifyInspection(input);
}
