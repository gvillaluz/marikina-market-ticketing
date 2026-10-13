import 'package:dio/dio.dart';
import 'package:marikina_market_mobile/core/errors/api_error_message.dart';
import 'package:marikina_market_mobile/core/errors/exceptions.dart';
import 'package:marikina_market_mobile/core/network/client.dart';
import 'package:marikina_market_mobile/features/auth/data/models/auth_tokens.dart';
import 'package:marikina_market_mobile/features/auth/data/models/login_otp_result_model.dart';
import 'package:marikina_market_mobile/features/auth/data/models/user_model.dart';
import 'package:marikina_market_mobile/features/auth/data/models/logout_request_model.dart';

abstract class AuthRemoteDataSource {
  Future<LoginOtpResultModel> login(String username, String password);
  Future<AuthTokens> verifyLogin(String username, String password, String code);
  Future<UserModel> getUser();
  Future<void> changePassword(
    int userId,
    String currentPassword,
    String newPassword,
    String confirmNewPassword,
  );
  Future<AuthTokens> refreshAuthTokens(String refreshToken);
  Future<void> registerDeviceToken(String deviceToken);
  Future<void> logout(LogoutRequestModel request);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;
  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<void> logout(LogoutRequestModel request) async {
    try {
      await apiClient.post(
        '/Auth/logout',
        data: request.toJson(),
        options: Options(
          contentType: Headers.jsonContentType,
          extra: {'skipAuth': true},
        ),
      );
    } on DioException catch (error) {
      final message = ApiErrorMessage.fromBody(error.response?.data) ?? '';
      if (error.response?.statusCode == 400) throw ValidationException(message);
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        throw NetworkException(message);
      }
      throw ServerException(message);
    }
  }

  @override
  Future<LoginOtpResultModel> login(String username, String password) async {
    try {
      final response = await apiClient.post(
        '/auth/login-mobile',
        data: {'username': username, 'password': password},
        options: Options(extra: {'skipAuth': true}),
      );
      return LoginOtpResultModel.fromJson(_jsonObject(response.data));
    } on DioException catch (e) {
      _throwLoginError(e);
    } on FormatException {
      throw ServerException(
        'Unable to read the login response. Please try again.',
      );
    }
  }

  @override
  Future<AuthTokens> verifyLogin(
    String username,
    String password,
    String code,
  ) async {
    try {
      final response = await apiClient.post(
        '/auth/verify-login-mobile',
        data: {'username': username, 'password': password, 'code': code},
        options: Options(extra: {'skipAuth': true}),
      );
      final json = _jsonObject(response.data);
      if (json['access_token'] is! String ||
          json['refresh_token'] is! String ||
          json['refresh_token_expiration'] is! String ||
          (json['access_token'] as String).isEmpty ||
          (json['refresh_token'] as String).isEmpty) {
        throw const FormatException('Invalid token response.');
      }
      return AuthTokens.fromJson(json);
    } on DioException catch (e) {
      _throwLoginError(e);
    } on FormatException {
      throw ServerException(
        'Unable to read the login response. Please try again.',
      );
    }
  }

  Map<String, Object?> _jsonObject(Object? value) {
    if (value is Map<String, Object?>) return value;
    throw const FormatException('Expected a JSON object.');
  }

  Never _throwLoginError(DioException error) {
    final message = ApiErrorMessage.fromBody(error.response?.data);
    final status = error.response?.statusCode;
    if (status == 400 || status == 403 || status == 423) {
      throw UnauthorizedException(
        message ??
            'Unable to sign in. Please check your details and try again.',
      );
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      throw NetworkException('No internet connection. Please try again.');
    }
    throw ServerException(
      message ?? 'Something went wrong. Please try again later.',
    );
  }

  @override
  Future<UserModel> getUser() async {
    try {
      final response = await apiClient.post('/user/me');

      return UserModel.fromJson(_jsonObject(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw UnauthorizedException(
          e.response?.data['message'] ?? 'Invalid username or password.',
        );
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('No internet connection. Please try again.');
      }

      throw ServerException('Something went wrong. Please try again later');
    } on FormatException {
      throw ServerException('Unable to read your profile. Please try again.');
    } on TypeError {
      throw ServerException('Unable to read your profile. Please try again.');
    } on ArgumentError {
      throw ServerException('Unable to read your profile. Please try again.');
    }
  }

  @override
  Future<void> changePassword(
    int userId,
    String currentPassword,
    String newPassword,
    String confirmNewPassword,
  ) async {
    try {
      await apiClient.post(
        '/auth/mandatory-change-password',
        data: {
          'user_id': userId,
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_new_password': confirmNewPassword,
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw TokenExpiredException("Invalid Session.");
      }

      if (e.response?.statusCode == 400) {
        throw UnauthorizedException(
          e.response?.data['message'] ?? 'Invalid current or new password.',
        );
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('No internet connection. Please try again.');
      }

      throw ServerException('Something went wrong. Please try again later');
    }
  }

  @override
  Future<AuthTokens> refreshAuthTokens(String refreshToken) async {
    try {
      final response = await apiClient.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(extra: {'skipAuth': true}),
      );

      return AuthTokens.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw UnauthorizedException(
          e.response?.data['message'] ?? 'Session expired.',
        );
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('No internet connection. Please try again.');
      }

      throw ServerException('Something went wrong. Please try again later');
    }
  }

  @override
  Future<void> registerDeviceToken(String deviceToken) async {
    try {
      await apiClient.post(
        '/user/device-token',
        data: {'device_token': deviceToken},
      );
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
