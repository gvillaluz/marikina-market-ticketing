import 'package:dio/dio.dart';
import 'package:marikina_market_mobile/core/errors/api_error_message.dart';
import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import '../../domain/entities/vendor_dashboard_summary.dart';
import '../../domain/repositories/vendor_dashboard_repository.dart';
import '../data_sources/vendor_dashboard_remote_data_source.dart';

class VendorDashboardRepositoryImpl implements VendorDashboardRepository {
  final VendorDashboardRemoteDataSource remote;
  const VendorDashboardRepositoryImpl(this.remote);

  @override
  Future<Result<VendorDashboardSummary>> loadDashboard() async {
    try {
      return Success((await remote.loadDashboard()).toEntity());
    } on DioException catch (error) {
      final message = ApiErrorMessage.fromBody(error.response?.data);
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        return ResultFailure(
          UnauthorizedFailure(
            message ?? 'Unable to access your dashboard. Please sign in again.',
          ),
        );
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return const ResultFailure(
          NetworkFailure('No internet connection. Please try again.'),
        );
      }
      return ResultFailure(
        ServerFailure(
          message ?? 'Unable to load your dashboard. Please try again.',
        ),
      );
    } on FormatException {
      return const ResultFailure(
        ServerFailure('Unable to read your dashboard. Please try again.'),
      );
    } on TypeError {
      return const ResultFailure(
        ServerFailure('Unable to read your dashboard. Please try again.'),
      );
    } on ArgumentError {
      return const ResultFailure(
        ServerFailure('Unable to read your dashboard. Please try again.'),
      );
    }
  }
}
