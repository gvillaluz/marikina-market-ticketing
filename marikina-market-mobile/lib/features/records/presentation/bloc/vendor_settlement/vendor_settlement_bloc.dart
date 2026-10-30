import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/ticket_receipt_proof.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/community_service_progress.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import '../../../domain/enums/records_filter.dart';
import '../../../domain/use_cases/load_vendor_receipt_use_case.dart';
import '../../../domain/use_cases/load_vendor_service_progress_use_case.dart';
import 'vendor_settlement_event.dart';
import 'vendor_settlement_state.dart';
import 'load_vendor_settlement.dart';

class VendorSettlementBloc
    extends Bloc<VendorSettlementEvent, VendorSettlementState> {
  final LoadVendorReceiptUseCase loadReceipt;
  final LoadVendorServiceProgressUseCase loadProgress;
  VendorSettlementBloc({required this.loadReceipt, required this.loadProgress})
    : super(const VendorSettlementState()) {
    on<LoadVendorSettlement>(_load);
  }
  Future<void> _load(
    LoadVendorSettlement event,
    Emitter<VendorSettlementState> emit,
  ) async {
    if (state.isLoading) return;
    final detail = event.detail;
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
    emit(VendorSettlementState(detail: detail, isLoading: true));
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
}
