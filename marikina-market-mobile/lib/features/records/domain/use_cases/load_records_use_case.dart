import 'package:marikina_market_mobile/core/errors/result.dart';
import '../entities/records_page_data.dart';
import '../enums/records_filter.dart';
import '../repositories/records_repository.dart';

class LoadRecordsUseCase {
  final RecordsRepository repository;
  const LoadRecordsUseCase(this.repository);
  Future<Result<RecordsPageData>> call({
    required String search,
    required int offset,
    required RecordsFilter filter,
  }) => repository.loadRecords(search: search, offset: offset, filter: filter);
}
