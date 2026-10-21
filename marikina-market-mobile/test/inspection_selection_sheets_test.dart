import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_hive_model.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_model.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/bottom_sheets/search_by_stall_bottom_sheet.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/bottom_sheets/select_ordinance_bottom_sheet.dart';
import 'inspection_list_ui_test.dart' show listBloc;
import 'features/tickets/presentation/inspection_photo_controls_test.dart'
    show
        captureFormControls,
        formControlsPreviewTheme,
        loadFormControlPreviewFonts;
import 'features/auth/data/login_mobile_contract_test.dart' show reply;
import 'features/tickets/data/models/ordinance_model_test.dart'
    show ordinanceResponse;

void main() {
  setUpAll(() async {
    await loadFormControlPreviewFonts();
    final adapter = OrdinanceHiveModelAdapter();
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  for (final width in [280.0, 400.0]) {
    for (final warning in [true, false]) {
      testWidgets(
        'full ordinance row and chip wrap at $width warning=$warning',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final payload = {
            ...ordinanceResponse,
            'ordinance_no': '2026-123456789',
            'series': '2026',
          };
          final selected = [OrdinanceModel.fromJson(payload).toEntity()];
          final bloc = await tester.runAsync(
            () => listBloc((options) async => reply(options, [payload])),
          );
          await tester.runAsync(() async {
            final loaded = bloc!.stream.firstWhere(
              (s) => s is OrdinanceSelectionLoaded,
            );
            bloc.add(LoadOrdinanceSelection());
            await loaded;
          });
          await tester.pumpWidget(
            BlocProvider<InspectionBloc>.value(
              value: bloc!,
              child: MaterialApp(
                theme: formControlsPreviewTheme,
                builder: (_, child) => RepaintBoundary(
                  key: const ValueKey('form-controls-preview'),
                  child: child!,
                ),
                home: Scaffold(
                  body: SelectOrdinanceBottomSheet(
                    isWarningTicket: warning,
                    ordinances: selected,
                    onChanged: (_) => fail('Draft selection must not commit'),
                    vendorId: 42,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          const label = 'Ord No. 2026-123456789, Series of 2026';
          expect(find.text(label), findsNWidgets(2));
          final chipLabel = find.descendant(
            of: find.byType(InputChip),
            matching: find.text(label),
          );
          if (width == 280) {
            expect(tester.getSize(chipLabel).height, greaterThan(20));
          }
          await captureFormControls(
            tester,
            'ordinance-${width.toInt()}-warning-$warning',
          );
          expect(find.text('MKT-001'), findsOneWidget);
          await tester.enterText(find.byType(TextField), '2026');
          await tester.pumpAndSettle();
          expect(find.text(label), findsNWidgets(2));
          await tester.tap(find.byTooltip('Clear search'));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Delete'));
          await tester.pumpAndSettle();
          expect(selected, hasLength(1));
          expect(find.text(label), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }

  test('a cleared vendor search ignores a late network response', () async {
    final request = Completer<RequestOptions>();
    final response = Completer<Response<Object?>>();
    final bloc = await listBloc((options) {
      request.complete(options);
      return response.future;
    });
    final states = <InspectionState>[];
    final subscription = bloc.stream.listen(states.add);
    addTearDown(subscription.cancel);
    bloc.add(SearchByStallNumberRequested('A-12'));
    final options = await request.future;
    final cleared = bloc.stream.firstWhere(
      (state) => state is InspectionInitial,
    );
    bloc.add(SearchByStallNumberRequested(''));
    await cleared;
    response.complete(reply(options, []));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(bloc.state, isA<InspectionInitial>());
    expect(states.whereType<InspectionSearchList>(), isEmpty);
  });

  test('a late older vendor request cannot replace the newer result', () async {
    final oldRequest = Completer<RequestOptions>();
    final newRequest = Completer<RequestOptions>();
    final oldResponse = Completer<Response<Object?>>();
    final newResponse = Completer<Response<Object?>>();
    final bloc = await listBloc((options) {
      if (options.path.endsWith('/A-12')) {
        oldRequest.complete(options);
        return oldResponse.future;
      }
      newRequest.complete(options);
      return newResponse.future;
    });
    final results = <InspectionSearchList>[];
    final subscription = bloc.stream.listen((state) {
      if (state is InspectionSearchList) results.add(state);
    });
    addTearDown(subscription.cancel);
    bloc.add(SearchByStallNumberRequested('A-12'));
    final oldOptions = await oldRequest.future;
    bloc.add(SearchByStallNumberRequested('A-13'));
    final newOptions = await newRequest.future;
    final loaded = bloc.stream.firstWhere(
      (state) => state is InspectionSearchList,
    );
    newResponse.complete(reply(newOptions, []));
    await loaded;
    oldResponse.complete(reply(oldOptions, []));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(results, hasLength(1));
  });

  testWidgets(
    'vendor sheet fits a narrow screen above the keyboard with large text',
    (tester) async {
      tester.view.physicalSize = const Size(280, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bloc = await tester.runAsync(
        () => listBloc((options) async => reply(options, [])),
      );
      await tester.pumpWidget(
        BlocProvider<InspectionBloc>.value(
          value: bloc!,
          child: MaterialApp(
            theme: AppTheme.light,
            home: MediaQuery(
              data: const MediaQueryData(
                textScaler: TextScaler.linear(2),
                viewInsets: EdgeInsets.only(bottom: 240),
                disableAnimations: true,
              ),
              child: const Scaffold(
                resizeToAvoidBottomInset: false,
                body: SearchByBusinessIdBottomSheet(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Select vendor'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
      expect(
        tester.getBottomLeft(find.byType(ElevatedButton)).dy,
        lessThanOrEqualTo(400),
      );
    },
  );

  testWidgets(
    'removing a draft ordinance does not mutate the parent selection',
    (tester) async {
      final selected = [OrdinanceModel.fromJson(ordinanceResponse).toEntity()];
      final bloc = await tester.runAsync(
        () => listBloc((options) async => reply(options, [ordinanceResponse])),
      );
      await tester.pumpWidget(
        BlocProvider<InspectionBloc>.value(
          value: bloc!,
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SelectOrdinanceBottomSheet(
                isWarningTicket: true,
                ordinances: selected,
                onChanged: (_) =>
                    fail('Unconfirmed selection must not be committed'),
                vendorId: 42,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final chip = tester.widget<InputChip>(find.byType(InputChip));
      chip.onDeleted!();
      await tester.pump();
      expect(selected, hasLength(1));
      expect(find.byType(InputChip), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'ordinance confirmation prevents repeated requests and restores controls after failure',
    (tester) async {
      tester.view.physicalSize = const Size(280, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final request = Completer<RequestOptions>();
      final response = Completer<Response<Object?>>();
      var checks = 0;
      final bloc = await tester.runAsync(
        () => listBloc((options) async {
          if (options.path == '/ordinance') {
            return reply(options, [ordinanceResponse]);
          }
          checks++;
          request.complete(options);
          return response.future;
        }),
      );
      await tester.runAsync(() async {
        final loaded = bloc!.stream.firstWhere(
          (state) => state is OrdinanceSelectionLoaded,
        );
        bloc.add(LoadOrdinanceSelection());
        await loaded;
      });
      await tester.pumpWidget(
        BlocProvider<InspectionBloc>.value(
          value: bloc!,
          child: MaterialApp(
            theme: AppTheme.light,
            home: MediaQuery(
              data: const MediaQueryData(
                textScaler: TextScaler.linear(2),
                viewInsets: EdgeInsets.only(bottom: 240),
                disableAnimations: true,
              ),
              child: Scaffold(
                resizeToAvoidBottomInset: false,
                body: SelectOrdinanceBottomSheet(
                  isWarningTicket: true,
                  ordinances: [
                    OrdinanceModel.fromJson(ordinanceResponse).toEntity(),
                  ],
                  onChanged: (_) => fail('Failed confirmation must not commit'),
                  vendorId: 42,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final confirm = tester
          .widget<ElevatedButton>(find.byType(ElevatedButton))
          .onPressed!;
      confirm();
      confirm();
      final options = await tester.runAsync(() => request.future);
      await tester.pump();
      expect(checks, 1);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      expect(
        tester.widget<InputChip>(find.byType(InputChip)).onDeleted,
        isNull,
      );
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final failed = bloc.stream.firstWhere(
          (state) => state is WarningOrdinanceCheckError,
        );
        response.completeError(
          DioException(
            requestOptions: options!,
            type: DioExceptionType.connectionError,
          ),
        );
        await failed;
      });
      await tester.pumpAndSettle();
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNotNull,
      );
      expect(
        tester.widget<InputChip>(find.byType(InputChip)).onDeleted,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
