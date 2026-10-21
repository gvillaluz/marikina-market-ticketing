import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/community_service_progress.dart';
import '../repositories/records_repository.dart';

class LoadVendorServiceProgressUseCase {
  final RecordsRepository repository;
  const LoadVendorServiceProgressUseCase(this.repository);
  Future<Result<CommunityServiceProgress>> call(int ticketId) =>
      repository.loadServiceProgress(ticketId);
}
