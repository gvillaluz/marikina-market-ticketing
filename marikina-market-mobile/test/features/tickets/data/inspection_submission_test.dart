import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/errors/exceptions.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/features/tickets/data/data_sources/inspection_remote_data_source.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/params/save_inspection_params.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';

import '../../auth/data/login_mobile_contract_test.dart' show contractClient;

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('issuance preserves the server validation message', () async {
    final client = contractClient((options) async {
      expect(options.path, '/enforcer/tickets/new-inspection');
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<Object?>(
          requestOptions: options,
          statusCode: 400,
          data: {'message': 'Photo evidence is required for tickets.'},
        ),
      );
    });
    addTearDown(client.dio.close);

    await expectLater(
      InspectionRemoteDataSourceImpl(client).saveInspection(
        SaveInspectionParams(
          vendorId: 17,
          marketSectionId: 1,
          enforcerId: 8,
          ticketType: ViolationType.ticket,
          description: 'Market identification card not displayed',
          penaltyType: PenaltyType.cashFine,
          communityServiceHours: null,
          ordinanceIds: [1],
          evidences: [],
        ),
      ),
      throwsA(
        isA<ValidationException>().having(
          (error) => error.message,
          'message',
          'Photo evidence is required for tickets.',
        ),
      ),
    );
  });
}
