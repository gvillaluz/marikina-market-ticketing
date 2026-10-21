import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/utils/unit.dart';

class ApiClient {
  final Dio dio;
  static const _storage = FlutterSecureStorage();
  final Future<Result<Unit>> Function()? refreshAction;
  final Future<Result<Unit>> Function()? waitForRefresh;
  final Future<void> Function()? onAuthFailure;

  Completer<Result<Unit>>? _refreshCompleter;

  ApiClient({
    Dio? dio,
    this.refreshAction,
    this.waitForRefresh,
    this.onAuthFailure,
  }) : dio = dio ?? Dio() {
    _configure();
  }

  Future<Result<Unit>> handleRefresh() {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    final completer = Completer<Result<Unit>>();
    _refreshCompleter = completer;

    refreshAction!()
        .then((success) {
          completer.complete(success);
          _refreshCompleter = null;
        })
        .catchError((_) {
          completer.complete(
            Result.failure(
              const ServerFailure(
                'Unable to renew your session. Please try again.',
              ),
            ),
          );
          _refreshCompleter = null;
        });

    return completer.future;
  }

  void _configure() {
    dio.options = BaseOptions(
      baseUrl: 'https://motocross-lifter-modified.ngrok-free.dev/api',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: kDebugMode
          ? const Duration(seconds: 60)
          : const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    );

    if (kDebugMode) {
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) {
                return host == '192.168.1.57';
              };
          return client;
        },
      );
    }

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final skipAuth = options.extra['skipAuth'] == true;

          if (skipAuth) {
            options.headers.remove('Authorization');
          }
          if (!skipAuth) {
            if (_refreshCompleter != null) {
              final result = await _refreshCompleter!.future;
              if (result case ResultFailure(failure: final failure)) {
                return handler.reject(await _refreshError(options, failure));
              }
            }

            final pendingRefresh = await waitForRefresh?.call();
            if (pendingRefresh case ResultFailure(failure: final failure)) {
              return handler.reject(await _refreshError(options, failure));
            }

            final token = await _storage.read(key: 'access_token');
            if (token != null) {
              options.headers['Authorization'] = _authorizationHeader(token);
            }
          }

          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          final isAlreadyRetried = e.requestOptions.extra['isRetry'] ?? false;
          final isRefreshCall = e.requestOptions.path.contains('/auth/refresh');

          if (e.response?.statusCode == 401 &&
              refreshAction != null &&
              e.requestOptions.extra['skipAuth'] != true &&
              !isAlreadyRetried &&
              !isRefreshCall) {
            final refreshResult = await handleRefresh();

            if (refreshResult case ResultFailure(failure: final failure)) {
              return handler.next(
                await _refreshError(e.requestOptions, failure),
              );
            }

            if (refreshResult is Success<Unit>) {
              final requestOptions = e.requestOptions;
              requestOptions.extra['isRetry'] = true;

              final newAccessToken = await _storage.read(key: 'access_token');

              if (newAccessToken != null) {
                requestOptions.headers['Authorization'] = _authorizationHeader(
                  newAccessToken,
                );

                if (requestOptions.data is FormData) {
                  final oldFormData = requestOptions.data as FormData;
                  final clonedFormData = FormData();

                  clonedFormData.fields.addAll(oldFormData.fields);

                  for (final file in oldFormData.files) {
                    clonedFormData.files.add(
                      MapEntry(file.key, file.value.clone()),
                    );
                  }

                  requestOptions.data = clonedFormData;
                }

                try {
                  final clonedResponse = await dio.fetch(requestOptions);
                  return handler.resolve(clonedResponse);
                } on DioException catch (retryError) {
                  return handler.next(retryError);
                }
              }
            }

            return handler.next(e);
          }

          return handler.next(e);
        },
      ),
    );
  }

  Future<DioException> _refreshError(
    RequestOptions options,
    Failure failure,
  ) async {
    final unauthorized = failure is UnauthorizedFailure;
    if (unauthorized) await onAuthFailure?.call();
    return DioException(
      requestOptions: options,
      type: unauthorized
          ? DioExceptionType.badResponse
          : failure is NetworkFailure
          ? DioExceptionType.connectionError
          : DioExceptionType.unknown,
      response: unauthorized
          ? Response<Object?>(
              requestOptions: options,
              statusCode: 401,
              data: {'message': failure.message},
            )
          : null,
      error: failure.message,
    );
  }

  String _authorizationHeader(String token) =>
      (StringBuffer('Bearer ')..write(token)).toString();

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.get(path, queryParameters: queryParameters, options: options);
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> delete(String path, {Options? options}) {
    return dio.delete(path, options: options);
  }
}
