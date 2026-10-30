import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_hive_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/violator_info_section.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/violation_details_section.dart';
import '../../../inspection_list_ui_test.dart' show listBloc;
import '../../../inspection_preview_navigation_test.dart' show vendor;
import 'person_verification_flow_test.dart' show BoundaryImageCompressor;

void main() {
  setUpAll(() {
    final adapter = OrdinanceHiveModelAdapter();
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test(
    'warning submission sends confirmed identity, actual place and one paper file',
    () async {
      final compressor = FlutterImageCompressPlatform.instance;
      FlutterImageCompressPlatform.instance = BoundaryImageCompressor();
      addTearDown(() => FlutterImageCompressPlatform.instance = compressor);
      final folder = await Directory.systemTemp.createTemp('warning-contract-');
      addTearDown(() => folder.delete(recursive: true));
      final file = await File('${folder.path}/paper.png').writeAsBytes(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a9ZkAAAAASUVORK5CYII=',
        ),
      );
      final captured = Completer<FormData>();
      final bloc = await listBloc((options) async {
        captured.complete(options.data as FormData);
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<Object?>(
            requestOptions: options,
            statusCode: 400,
            data: {
              'message':
                  'Synthetic rejection after observing the multipart request.',
            },
          ),
        );
      });
      bloc.add(
        NewInspectionSubmitted(
          personId: 31,
          issuePlace: 'Fish aisle near F-014',
          vendorId: 17,
          enforcerId: 8,
          marketSectionId: 1,
          ticketType: ViolationType.warning,
          ordinanceIds: [1],
          penaltyType: PenaltyType.cashFine,
          communityServiceHours: null,
          description: 'Market identification card not displayed',
          primaryCategory: [],
          evidences: [],
          paperTicketPhoto: XFile(file.path),
        ),
      );
      final form = await captured.future.timeout(const Duration(seconds: 5));
      final fields = Map.fromEntries(form.fields);
      expect(fields['person_id'], '31');
      expect(fields['issue_place'], 'Fish aisle near F-014');
      expect(form.files.map((entry) => entry.key), ['paper_ticket_photo']);
    },
  );

  for (final width in [280.0, 400.0]) {
    testWidgets(
      'warning preview distinguishes person, owner and place at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      const ViolatorInfoSection(
                        vendor: vendor,
                        isTicket: false,
                        personId: 31,
                        personFullName: 'Juan Dela Cruz',
                      ),
                      const ViolationDetailsSection(
                        ordinances: [],
                        isTicket: false,
                        marketSection: 'Section A',
                        issuePlace: 'Fish aisle near F-014',
                        description: 'Market identification card not displayed',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        expect(find.text('CONFIRMED PERSON:'), findsOneWidget);
        expect(find.textContaining('Juan Dela Cruz'), findsOneWidget);
        expect(find.text('Fish aisle near F-014'), findsOneWidget);
        expect(find.text('Assigned when saved'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
