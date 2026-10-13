import '../../../domain/enums/records_filter.dart';

class LoadRecords {
  final String search;
  final RecordsFilter filter;
  final int offset;
  const LoadRecords({
    this.search = '',
    this.filter = RecordsFilter.all,
    this.offset = 0,
  });
}
