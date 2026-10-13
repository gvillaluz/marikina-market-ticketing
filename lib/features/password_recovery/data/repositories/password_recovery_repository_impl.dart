import 'package:marikina_market_mobile/core/errors/exceptions.dart';
import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/password_recovery/data/data_sources/password_recovery_remote_data_source.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/entities/account_lookup.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/entities/otp_send_result.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/entities/reset_password_result.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/entities/verify_code_result.dart';
import 'package:marikina_market_mobile/features/password_recovery/domain/repositories/password_recovery_repository.dart';

class PasswordRecoveryRepositoryImpl implements PasswordRecoveryRepository {
  final PasswordRecoveryRemoteDataSource remoteDataSource;
  const PasswordRecoveryRepositoryImpl(this.remoteDataSource);

  @override
  Future<Result<AccountLookup>> findAccount(String username) async {
    try {
      final lookupModel = await remoteDataSource.findAccount(username);

      return Result.success(lookupModel.toEntity());
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<OtpSendResult>> sendOtp(String username, String channel) async {
    try {
      final otpResult = await remoteDataSource.sendOtp(username, channel);

      return Result.success(otpResult.toEntity());
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<VerifyCodeResult>> verifyCode(
    String username,
    String code,
  ) async {
    try {
      final otpResult = await remoteDataSource.verifyCode(username, code);

      return Result.success(otpResult.toEntity());
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<ResetPasswordResult>> resetPassword(
    String username,
    String newPassword,
    String resetToken,
  ) async {
    try {
      final result = await remoteDataSource.resetPassword(
        username,
        newPassword,
        resetToken,
      );

      return Result.success(result.toEntity());
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message));
    }
  }
}
