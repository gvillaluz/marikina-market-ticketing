import 'vendor_record.dart';

class RecordsPageData {
  final List<VendorRecord> items;
  final bool hasMore;
  final int total;
  const RecordsPageData({
    required this.items,
    required this.hasMore,
    required this.total,
  });
}
