import 'vendor_settlement_event.dart';

class SubmitVendorReceipt extends VendorSettlementEvent {
  final String filePath;
  const SubmitVendorReceipt(this.filePath);
}
