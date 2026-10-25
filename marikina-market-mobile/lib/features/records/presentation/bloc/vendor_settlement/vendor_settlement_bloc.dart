import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/ticket_receipt_proof.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/community_service_progress.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import '../../../domain/entities/submit_vendor_receipt_params.dart';
import '../../../domain/enums/records_filter.dart';
import '../../../domain/use_cases/load_vendor_receipt_use_case.dart';
import '../../../domain/use_cases/load_vendor_service_progress_use_case.dart';
import '../../../domain/use_cases/submit_vendor_receipt_use_case.dart';
import 'vendor_settlement_event.dart';
import 'vendor_settlement_state.dart';
import 'load_vendor_settlement.dart';
import 'submit_vendor_receipt.dart';
import 'clear_vendor_receipt_upload_error.dart';

class VendorSettlementBloc
    extends Bloc<VendorSettlementEvent, VendorSettlementState> {
  final LoadVendorReceiptUseCase loadReceipt;
  final LoadVendorServiceProgressUseCase loadProgress;
  final SubmitVendorReceiptUseCase submitReceipt;
  VendorSettlementBloc({
    required this.loadReceipt,
    required this.loadProgress,
    required this.submitReceipt,
  }) : super(const VendorSettlementState()) {
    on<LoadVendorSettlement>(_load);
    on<SubmitVendorReceipt>(_submit);
    on<ClearVendorReceiptUploadError>((event, emit) {
      if (!state.canUpload || state.uploadError == null) return;
      emit(state.copyWith(error: state.error));
    });
  }
  Future<void> _load(
    LoadVendorSettlement event,
    Emitter<VendorSettlementState> emit,
  ) async {
    if (state.isLoading || state.isUploading) return;
    final detail = event.detail;
    final locked =
        state.hasUploaded && state.detail?.ticketId == detail.ticketId;
    if (detail.type == RecordsFilter.warning) {
      emit(VendorSettlementState(detail: detail));
      return;
    }
    final service = detail.penaltyType == PenaltyType.communityService.value;
    final receipt =
        detail.penaltyType == PenaltyType.cashFine.value ||
        detail.penaltyType == PenaltyType.bloodDonation.value;
    if (!service && !receipt) {
      emit(
        VendorSettlementState(
          detail: detail,
          error: 'Settlement details are unavailable for this ticket.',
        ),
      );
      return;
    }
    emit(
      VendorSettlementState(
        detail: detail,
        isLoading: true,
        hasUploaded: locked,
      ),
    );
    if (service) {
      final result = await loadProgress(detail.ticketId);
      if (emit.isDone) return;
      switch (result) {
        case Success<CommunityServiceProgress>(data: final progress):
          emit(
            state.copyWith(
              progress: progress,
              isLoading: false,
              isLoaded: true,
            ),
          );
        case ResultFailure<CommunityServiceProgress>(failure: final failure):
          emit(state.copyWith(isLoading: false, error: failure.message));
      }
    } else {
      final result = await loadReceipt(detail.ticketId);
      if (emit.isDone) return;
      switch (result) {
        case Success<TicketReceiptProof>(data: final proof):
          if (proof.penaltyType.value != detail.penaltyType) {
            emit(
              state.copyWith(
                isLoading: false,
                error: 'Settlement type does not match this ticket.',
              ),
            );
          } else {
            emit(
              state.copyWith(receipt: proof, isLoading: false, isLoaded: true),
            );
          }
        case ResultFailure<TicketReceiptProof>(failure: final failure):
          emit(state.copyWith(isLoading: false, error: failure.message));
      }
    }
  }

  Future<void> _submit(
    SubmitVendorReceipt event,
    Emitter<VendorSettlementState> emit,
  ) async {
    if (!state.canUpload) return;
    final id = state.detail!.ticketId;
    emit(state.copyWith(isUploading: true));
    final result = await submitReceipt(
      SubmitVendorReceiptParams(ticketId: id, filePath: event.filePath),
    );
    if (emit.isDone) return;
    switch (result) {
      case Success<TicketReceiptProof>(data: final receipt):
        emit(
          state.copyWith(
            receipt: receipt,
            isUploading: false,
            hasUploaded: true,
          ),
        );
      case ResultFailure<TicketReceiptProof>(failure: final failure):
        final uncertain =
            failure is NetworkFailure ||
            failure is ServerFailure ||
            failure is UnauthorizedFailure;
        emit(
          state.copyWith(
            isUploading: false,
            isLoaded: !uncertain,
            error: uncertain ? failure.message : null,
            uploadError: failure.message,
          ),
        );
    }
  }
}
