import '../../../domain/entities/vendor_ticket_detail.dart';

class RecordDetailState {
  final VendorTicketDetail? detail;
  final bool isLoading;
  final String? error;
  const RecordDetailState({this.detail, this.isLoading = true, this.error});
}
