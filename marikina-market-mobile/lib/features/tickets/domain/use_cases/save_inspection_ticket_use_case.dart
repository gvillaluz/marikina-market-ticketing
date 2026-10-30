import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/usecases/usecase.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/params/save_inspection_params.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/save_inspection_result.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/domain/repositories/inspection_repository.dart';

class SaveInspectionTicketUseCase
    implements UseCase<SaveInspectionResult, SaveInspectionParams> {
  final InspectionRepository _repository;
  SaveInspectionTicketUseCase(this._repository);

  @override
  Future<Result<SaveInspectionResult>> call(SaveInspectionParams params) async {
    if (params.ordinanceIds.isEmpty) {
      return Result.failure(
        ValidationFailure('At least one ordinance must be selected.'),
      );
    }

    if (params.ticketType == ViolationType.warning &&
        params.ordinanceIds.length > 1) {
      return Result.failure(
        ValidationFailure('Warnings can only have one ordinance.'),
      );
    }

    if (params.description.trim().isEmpty) {
      return Result.failure(ValidationFailure('Description is required.'));
    }

    if (params.ticketType == ViolationType.warning) {
      if (params.personId == null ||
          params.personId! <= 0 ||
          params.vendorId <= 0) {
        return Result.failure(
          ValidationFailure(
            'Confirm the person and business for this warning.',
          ),
        );
      }
      if (params.issuePlace == null ||
          params.issuePlace!.trim().isEmpty ||
          params.issuePlace!.trim().length > 500 ||
          params.description.length > 1000) {
        return Result.failure(
          ValidationFailure(
            'Enter the warning description and actual issue place.',
          ),
        );
      }
      if (params.paperTicketPhoto == null ||
          (params.evidences?.isNotEmpty ?? false)) {
        return Result.failure(
          ValidationFailure(
            'Warnings require one paper photo and no supporting evidence.',
          ),
        );
      }
    }

    if (params.ticketType == ViolationType.ticket) {
      if (params.paperReference == null ||
          params.paperReference!.trim().isEmpty ||
          params.issuePlace == null ||
          params.issuePlace!.trim().isEmpty ||
          params.paperReference!.trim().length > 200 ||
          params.issuePlace!.trim().length > 500) {
        return Result.failure(
          ValidationFailure(
            'Enter the reviewed paper reference and issue place.',
          ),
        );
      }
      if (params.paperTicketPhoto == null ||
          params.evidences == null ||
          params.evidences!.isEmpty) {
        return Result.failure(
          ValidationFailure(
            'One paper ticket photo and at least one supporting photo are required for tickets.',
          ),
        );
      }

      if (params.penaltyType == PenaltyType.communityService) {
        if (params.communityServiceHours == null ||
            params.communityServiceHours! < 3) {
          return Result.failure(
            ValidationFailure(
              'Community service requires a minimum of 3 hours.',
            ),
          );
        }
      }
    }

    return await _repository.saveNewInspection(
      // Preserve the confirmed identity and Verify snapshot across this boundary.
      SaveInspectionParams(
        personId: params.personId,
        paperViolatorName: params.paperViolatorName,
        paperReference: params.paperReference?.trim(),
        issuePlace: params.issuePlace?.trim(),
        reviewedCalculation: params.reviewedCalculation,
        reviewedBusinessSnapshot: params.reviewedBusinessSnapshot,
        vendorId: params.vendorId,
        marketSectionId: params.marketSectionId,
        enforcerId: params.enforcerId,
        ticketType: params.ticketType,
        description: params.description,
        penaltyType: params.penaltyType,
        communityServiceHours: params.communityServiceHours,
        ordinanceIds: params.ordinanceIds,
        evidences: params.evidences,
        paperTicketPhoto: params.paperTicketPhoto,
      ),
    );
  }
}
