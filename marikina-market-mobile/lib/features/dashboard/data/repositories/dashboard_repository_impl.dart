import 'package:marikina_market_mobile/core/errors/exceptions.dart';
import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/dashboard/data/data_sources/dashboard_remote_data_source.dart';
import 'package:marikina_market_mobile/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:marikina_market_mobile/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;
  DashboardRepositoryImpl(this.remoteDataSource);

  @override
  Future<Result<DashboardSummary>> loadDashboard() async {
    try {
      final dashboardModel = await remoteDataSource.getDashboardSummary();
      return Result.success(dashboardModel.toEntity());
    } on UnauthorizedException catch (e) {
      return Result.failure(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message));
    }
  }
}