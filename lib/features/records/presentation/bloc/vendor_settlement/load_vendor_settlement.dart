import '../../../domain/entities/vendor_ticket_detail.dart';
import 'vendor_settlement_event.dart';

class LoadVendorSettlement extends VendorSettlementEvent {
  final VendorTicketDetail detail;
  const LoadVendorSettlement(this.detail);
}
