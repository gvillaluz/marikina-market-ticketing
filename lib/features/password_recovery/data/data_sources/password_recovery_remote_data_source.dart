import 'package:dio/dio.dart';
import 'package:marikina_market_mobile/core/errors/exceptions.dart';
import 'package:marikina_market_mobile/core/network/client.dart';
import 'package:marikina_market_mobile/features/password_recovery/data/models/account_lookup_model.dart';
import 'package:marikina_market_mobile/features/password_recovery/data/models/otp_send_result_model.dart';
import 'package:marikina_market_mobile/features/password_recovery/data/models/reset_password_result_model.dart';
import 'package:marikina_market_mobile/features/password_recovery/data/models/verify_code_result_model.dart';

abstract class PasswordRecoveryRemoteDataSource {
  Future<AccountLookupModel> findAccount(String username);
  Future<OtpSendResultModel> sendOtp(String username, String channel);
  Future<VerifyCodeResultModel> verifyCode(String username, String code);
  Future<ResetPasswordResultModel> resetPassword(
    String username,
    String newPassword,
    String resetToken,
  );
}

class PasswordRecoveryRemoteDataSourceImpl
    implements PasswordRecoveryRemoteDataSource {
  final ApiClient apiClient;
  const PasswordRecoveryRemoteDataSourceImpl(this.apiClient);

  @override
  Future<AccountLookupModel> findAccount(String username) async {
    try {
      final response = await apiClient.post(
        '/auth/find-account',
        data: {'username': username},
      );

      return AccountLookupModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('No internet connection. Please try again.');
      }

      throw ServerException('Something went wrong. Please try again later');
    }
  }

  @override
  Future<OtpSendResultModel> sendOtp(String username, String channel) async {
    try {
      final response = await apiClient.post(
        '/auth/send-otp',
        data: {'username': username, 'channel': channel},
      );

      return OtpSendResultModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('No internet connection. Please try again.');
      }

      throw ServerException('Something went wrong. Please try again later');
    }
  }

  @override
  Future<VerifyCodeResultModel> verifyCode(String username, String code) async {
    try {
      final response = await apiClient.post(
        '/auth/verify-otp',
        data: {'username': username, 'code': code},
      );

      return VerifyCodeResultModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('No internet connection. Please try again.');
      }

      throw ServerException('Something went wrong. Please try again later');
    }
  }

  @override
  Future<ResetPasswordResultModel> resetPassword(
    String username,
    String newPassword,
    String resetToken,
  ) async {
    try {
      final response = await apiClient.post(
        '/auth/reset-password',
        data: {
          'username': username,
          'new_password': newPassword,
          'reset_token': resetToken,
        },
      );

      return ResetPasswordResultModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('No internet connection. Please try again.');
      }

      throw ServerException('Something went wrong. Please try again later');
    }
  }
}
