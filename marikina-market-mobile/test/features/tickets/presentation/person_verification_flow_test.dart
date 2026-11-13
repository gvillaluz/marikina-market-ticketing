import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_hive_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_assessment.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/ordinance_category.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_event.dart';
import '../../../inspection_list_ui_test.dart' show listBloc;

void main() {
  setUpAll(() {
    final adapter = OrdinanceHiveModelAdapter();
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test(
    'citation submission preserves the confirmed identity through the real use case and multipart boundary',
    () async {
      final original = FlutterImageCompressPlatform.instance;
      FlutterImageCompressPlatform.instance = BoundaryImageCompressor();
      addTearDown(() => FlutterImageCompressPlatform.instance = original);
      final folder = await Directory.systemTemp.createTemp(
        'person-submit-contract-',
      );
      final photo = await File('${folder.path}/synthetic.png').writeAsBytes(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a9ZkAAAAASUVORK5CYII=',
        ),
      );
      addTearDown(() => folder.delete(recursive: true));
      final captured = Completer<Map<String, String>>();
      final bloc = await listBloc((options) async {
        final form = options.data as FormData;
        captured.complete(Map.fromEntries(form.fields));
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<Object?>(
            requestOptions: options,
            statusCode: 400,
            data: {
              'message':
                  'Synthetic rejection after inspecting the outgoing request.',
            },
          ),
        );
      });
      bloc.add(
        NewInspectionSubmitted(
          fineAssessments: const [
            FineAssessment(ordinanceId: 1, assessedAmount: 500),
          ],
          personId: 31,
          paperViolatorName: 'Juan Cruz',
          paperReference: '000456',
          issuePlace: 'Fish aisle near F-014',
          vendorId: 17,
          enforcerId: 7,
          marketSectionId: 1,
          ticketType: ViolationType.ticket,
          ordinanceIds: [1],
          penaltyType: PenaltyType.cashFine,
          communityServiceHours: null,
          description: 'Synthetic market aisle obstruction',
          primaryCategory: <OrdinanceCategory>[],
          evidences: [XFile(photo.path)],
          paperTicketPhoto: XFile(photo.path),
        ),
      );
      final fields = await captured.future.timeout(const Duration(seconds: 5));
      expect(fields['person_id'], '31');
      expect(fields['paper_violator_name'], 'Juan Cruz');
      expect(fields.keys, isNot(contains('reviewed_calculation')));
      expect(fields.keys, isNot(contains('reviewed_business_snapshot')));
      expect(fields['vendor_id'], '17');
      expect(fields['paper_reference'], '000456');
      expect(fields['issue_place'], 'Fish aisle near F-014');
      expect(jsonDecode(fields['fine_assessments']!), [
        {'ordinance_id': 1, 'assessed_amount': 500.0},
      ]);
    },
  );
}

// Native image compression is the only non-network boundary replaced in this test.
class BoundaryImageCompressor extends FlutterImageCompressPlatform {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<XFile?> compressAndGetFile(
    String path,
    String targetPath, {
    int minWidth = 1920,
    int minHeight = 1080,
    int inSampleSize = 1,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
    int numberOfRetries = 5,
  }) async => null;
}
