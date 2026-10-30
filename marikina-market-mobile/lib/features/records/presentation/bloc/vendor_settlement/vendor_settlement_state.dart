import 'package:marikina_market_mobile/core/shared/domain/entities/ticket_receipt_proof.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/community_service_progress.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import '../../../domain/entities/vendor_ticket_detail.dart';

class VendorSettlementState {
  final VendorTicketDetail? detail;
  final TicketReceiptProof? receipt;
  final CommunityServiceProgress? progress;
  final bool isLoading, isLoaded;
  final String? error;
  const VendorSettlementState({
    this.detail,
    this.receipt,
    this.progress,
    this.isLoading = false,
    this.isLoaded = false,
    this.error,
  });
  bool get isService =>
      detail?.penaltyType == PenaltyType.communityService.value;
  VendorSettlementState copyWith({
    TicketReceiptProof? receipt,
    CommunityServiceProgress? progress,
    bool? isLoading,
    bool? isLoaded,
    String? error,
  }) => VendorSettlementState(
    detail: detail,
    receipt: receipt ?? this.receipt,
    progress: progress ?? this.progress,
    isLoading: isLoading ?? this.isLoading,
    isLoaded: isLoaded ?? this.isLoaded,
    error: error,
  );
}
