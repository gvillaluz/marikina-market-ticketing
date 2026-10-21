import 'package:marikina_market_mobile/core/shared/domain/entities/ticket_receipt_proof.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/community_service_progress.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import '../../../domain/entities/vendor_ticket_detail.dart';
import '../../../domain/enums/records_filter.dart';

class VendorSettlementState {
  final VendorTicketDetail? detail;
  final TicketReceiptProof? receipt;
  final CommunityServiceProgress? progress;
  final bool isLoading, isLoaded, isUploading, hasUploaded;
  final String? error, uploadError;
  const VendorSettlementState({
    this.detail,
    this.receipt,
    this.progress,
    this.isLoading = false,
    this.isLoaded = false,
    this.isUploading = false,
    this.hasUploaded = false,
    this.error,
    this.uploadError,
  });
  bool get isService =>
      detail?.penaltyType == PenaltyType.communityService.value;
  bool get canUpload =>
      detail?.type == RecordsFilter.ticket &&
      (detail?.penaltyType == PenaltyType.cashFine.value ||
          detail?.penaltyType == PenaltyType.bloodDonation.value) &&
      detail?.status != null &&
      detail?.status != TicketStatus.paid &&
      isLoaded &&
      !isUploading &&
      !hasUploaded &&
      receipt != null &&
      receipt!.proofUrls.isEmpty;
  VendorSettlementState copyWith({
    TicketReceiptProof? receipt,
    CommunityServiceProgress? progress,
    bool? isLoading,
    bool? isLoaded,
    bool? isUploading,
    bool? hasUploaded,
    String? error,
    String? uploadError,
  }) => VendorSettlementState(
    detail: detail,
    receipt: receipt ?? this.receipt,
    progress: progress ?? this.progress,
    isLoading: isLoading ?? this.isLoading,
    isLoaded: isLoaded ?? this.isLoaded,
    isUploading: isUploading ?? this.isUploading,
    hasUploaded: hasUploaded ?? this.hasUploaded,
    error: error,
    uploadError: uploadError,
  );
}
