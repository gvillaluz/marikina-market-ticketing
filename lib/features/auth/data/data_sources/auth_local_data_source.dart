import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:marikina_market_mobile/features/auth/data/models/logout_request_model.dart';

import 'package:marikina_market_mobile/core/errors/exceptions.dart';
import 'package:marikina_market_mobile/core/storage/secure_storage_service.dart';
import 'package:marikina_market_mobile/features/auth/data/models/auth_tokens.dart';
import 'package:marikina_market_mobile/features/auth/data/models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<AuthTokens> getTokens();
  Future<void> storeTokens(AuthTokens tokens);
  Future<void> storeUser(UserModel user);
  Future<UserModel> getUser();
  Future<void> removeUser();
  Future<LogoutRequestModel?> getLogoutRequest();
  Future<List<LogoutRequestModel>> getPendingLogouts();
  Future<void> savePendingLogouts(List<LogoutRequestModel> requests);
  Future<String> getDeviceTokenForRegistration();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SecureStorageService storageService;
  final FirebaseMessaging? _messaging;
  AuthLocalDataSourceImpl({
    required this.storageService,
    FirebaseMessaging? messaging,
  }) : _messaging = messaging;

  @override
  Future<AuthTokens> getTokens() async {
    final accessToken = await storageService.getAccessToken();
    final refreshToken = await storageService.getRefreshToken();
    final refreshTokenExpiration = await storageService
        .getRefreshTokenExpiration();

    if (accessToken == null ||
        refreshToken == null ||
        refreshTokenExpiration == null) {
      throw CacheException('No authentication tokens.');
    }

    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      refreshTokenExpiration: DateTime.parse(refreshTokenExpiration),
    );
  }

  @override
  Future<void> storeTokens(AuthTokens tokens) async {
    await storageService.saveTokens(
      tokens.accessToken,
      tokens.refreshToken,
      tokens.refreshTokenExpiration.toIso8601String(),
    );
  }

  @override
  Future<void> storeUser(UserModel user) async {
    await storageService.saveUser(jsonEncode(user.toJson()));
  }

  @override
  Future<UserModel> getUser() async {
    try {
      final userCache = await storageService.getUser();
      if (userCache == null) {
        throw CacheException('No user information stored.');
      }
      final json = jsonDecode(userCache);
      if (json is! Map<String, Object?>) throw const FormatException();
      return UserModel.fromJson(json);
    } on CacheException {
      rethrow;
    } catch (_) {
      throw CacheException(
        'Unable to read your saved profile. Please sign in again.',
      );
    }
  }

  @override
  Future<void> removeUser() async {
    try {
      await storageService.deleteUserAndToken();
    } catch (_) {
      throw CacheException('Unable to clear the session on this device.');
    }
  }

  @override
  Future<LogoutRequestModel?> getLogoutRequest() async {
    try {
      var deviceToken = await storageService.getDeviceToken();
      if (deviceToken == null) {
        final pending = await getPendingLogouts();
        if (pending.isNotEmpty) deviceToken = pending.last.deviceToken;
      }
      if (deviceToken == null) {
        try {
          deviceToken = await (_messaging ?? FirebaseMessaging.instance)
              .getToken()
              .timeout(const Duration(seconds: 5));
        } catch (_) {
          // Previously registered tokens are cached for offline logout.
        }
      }
      if (deviceToken == null) return null;
      final refreshToken = await storageService.getRefreshToken();
      return LogoutRequestModel(
        deviceToken: deviceToken,
        refreshToken: refreshToken == null || refreshToken.isEmpty
            ? null
            : refreshToken,
      );
    } catch (_) {
      throw CacheException('Unable to read the logout request on this device.');
    }
  }

  @override
  Future<List<LogoutRequestModel>> getPendingLogouts() async {
    try {
      final stored = await storageService.getPendingLogouts();
      if (stored == null) return [];
      final json = jsonDecode(stored);
      if (json is! List<Object?>) throw const FormatException();
      return json.map((item) {
        if (item is! Map<String, Object?>) throw const FormatException();
        return LogoutRequestModel.fromJson(item);
      }).toList();
    } catch (_) {
      throw CacheException('Unable to read pending logout requests.');
    }
  }

  @override
  Future<void> savePendingLogouts(List<LogoutRequestModel> requests) async {
    try {
      if (requests.isEmpty) {
        await storageService.deletePendingLogouts();
      } else {
        await storageService.savePendingLogouts(
          jsonEncode(requests.map((request) => request.toJson()).toList()),
        );
      }
    } catch (_) {
      throw CacheException('Unable to save pending logout requests.');
    }
  }

  @override
  Future<String> getDeviceTokenForRegistration() async {
    final settings = await (_messaging ?? FirebaseMessaging.instance)
        .requestPermission(alert: true, badge: true, sound: true);
    final token = await (_messaging ?? FirebaseMessaging.instance).getToken();
    if (token != null) {
      try {
        await storageService.saveDeviceToken(token);
      } catch (_) {
        throw CacheException('Unable to save the device token.');
      }
    }
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      throw ValidationException('Push notification permission denied.');
    }
    if (token == null) {
      throw ServerException('Unable to retrieve device token.');
    }
    return token;
  }
}
