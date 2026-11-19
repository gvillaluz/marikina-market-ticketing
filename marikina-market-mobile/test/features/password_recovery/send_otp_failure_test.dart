import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/errors/exceptions.dart';
import 'package:marikina_market_mobile/features/password_recovery/data/data_sources/password_recovery_remote_data_source.dart';
import '../auth/data/login_mobile_contract_test.dart' show contractClient;

Future<Object> failureFor(int status, Object? body) async {
  final client = contractClient(
    (options) async => throw DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response<Object?>(
        requestOptions: options,
        statusCode: status,
        data: body,
      ),
    ),
  );
  try {
    await PasswordRecoveryRemoteDataSourceImpl(
      client,
    ).sendOtp('enforcer01', 'email');
    throw StateError('Expected the request to fail.');
  } on ServerException catch (error) {
    return error.message;
  } finally {
    client.dio.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('503 shows the server message that the code could not be sent', () async {
    expect(
      await failureFor(503, {
        'message':
            'Unable to send your verification code. Please try again shortly.',
      }),
      'Unable to send your verification code. Please try again shortly.',
    );
  });

  test('other server errors keep the general message', () async {
    expect(
      await failureFor(500, {
        'message': 'An unexpected server error occurred.',
      }),
      'Something went wrong. Please try again later',
    );
  });
}
