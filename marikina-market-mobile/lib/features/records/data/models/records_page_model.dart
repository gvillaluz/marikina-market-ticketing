import '../../domain/entities/records_page_data.dart';
import 'vendor_record_model.dart';

class RecordsPageModel {
  final Map<String, Object?> json;
  const RecordsPageModel._(this.json);
  factory RecordsPageModel.fromJson(Map<String, Object?> json) =>
      RecordsPageModel._(json);
  RecordsPageData toEntity() {
    final total = json['total'] as int;
    if (total < 0) throw const FormatException('Invalid total.');
    return RecordsPageData(
      items: List.unmodifiable(
        (json['items'] as List<Object?>).map(
          (item) => VendorRecordModel.fromJson(
            item as Map<String, Object?>,
          ).toEntity(),
        ),
      ),
      hasMore: json['has_more'] as bool,
      total: total,
    );
  }
}
