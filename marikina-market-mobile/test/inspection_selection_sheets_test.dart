import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_primary_btn.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_hive_model.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/ordinance_model.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/bottom_sheets/ordinance_card.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/bottom_sheets/search_business_bottom_sheet.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/bottom_sheets/select_ordinance_bottom_sheet.dart';
import 'ordinance_shortcuts_test.dart' show withNoShortcuts;
import 'inspection_list_ui_test.dart' show listBloc;
import 'features/tickets/presentation/inspection_photo_controls_test.dart'
    show
        captureFormControls,
        formControlsPreviewTheme,
        loadFormControlPreviewFonts;
import 'features/auth/data/login_mobile_contract_test.dart' show reply;
import 'features/tickets/data/models/ordinance_model_test.dart'
    show ordinanceResponse;

// The tap handler of the only ordinance card, even when it is off screen.
VoidCallback? cardTap(WidgetTester tester) => tester
    .widget<InkWell>(
      find.descendant(
        of: find.byType(OrdinanceCard, skipOffstage: false),
        matching: find.byType(InkWell, skipOffstage: false),
      ),
    )
    .onTap;

void main() {
  setUpAll(() async {
    await loadFormControlPreviewFonts();
    final adapter = OrdinanceHiveModelAdapter();
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  for (final disableAnimations in [true, false]) {
    testWidgets(
      'loading primary button has valid semantics: disableAnimations=$disableAnimations',
      (tester) async {
        final semantics = tester.ensureSemantics();
        var presses = 0;
        try {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              home: MediaQuery(
                data: MediaQueryData(disableAnimations: disableAnimations),
                child: Scaffold(
                  body: AppPrimaryButton(
                    label: 'Confirm selection',
                    iconData: Icons.check,
                    isLoading: true,
                    onPressed: () => presses++,
                  ),
                ),
              ),
            ),
          );
          final indicator = find.byType(CircularProgressIndicator);
          final data = tester.getSemantics(indicator).getSemanticsData();
          expect(data.label, 'Loading\nConfirm selection');
          expect(data.value, disableAnimations ? '75' : '');
          expect(data.minValue, disableAnimations ? '0' : isNull);
          expect(data.maxValue, disableAnimations ? '100' : isNull);
          expect(
            tester
                .widget<ElevatedButton>(find.byType(ElevatedButton))
                .onPressed,
            isNull,
          );
          await tester.tap(find.text('Confirm selection'));
          expect(presses, 0);
          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.binding.hasScheduledFrame, !disableAnimations);
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          semantics.dispose();
        }
      },
    );
  }

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
            'category': 'Others',
            'severity': 'High',
            'warning_eligible': true,
            'specific_category': 'Market clearance and stall requirements',
          };
          final selected = [OrdinanceModel.fromJson(payload).toEntity()];
          final bloc = await tester.runAsync(
            () => listBloc(
              withNoShortcuts(
                (options) async => reply(options, [
                  payload,
                  {
                    ...ordinanceResponse,
                    'id': 2,
                    'section': '70',
                    'ordinance_no': 'Minor without warning permission',
                    'severity': 'Minor',
                    'warning_eligible': false,
                  },
                ]),
              ),
            ),
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
          expect(
            find.textContaining('Minor without warning permission'),
            warning ? findsNothing : findsOneWidget,
          );
          const label = 'Ord No. 2026-123456789, Series of 2026';
          expect(
            find.textContaining(
              'Others: Market clearance and stall requirements',
            ),
            findsOneWidget,
          );
          expect(find.text(label), findsOneWidget);
          expect(find.byType(InputChip), findsNothing);
          expect(find.text('1 selected'), findsOneWidget);
          await captureFormControls(
            tester,
            'ordinance-${width.toInt()}-warning-$warning',
          );
          expect(find.textContaining('Section 69'), findsOneWidget);
          await tester.enterText(find.byType(TextField), '2026');
          await tester.pumpAndSettle();
          expect(find.text(label), findsOneWidget);
          await tester.tap(find.byTooltip('Clear search'));
          await tester.pumpAndSettle();
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
          expect(selected, hasLength(1));
          expect(find.text(label), findsOneWidget);
          expect(find.text('1 selected'), findsNothing);
          expect(find.byIcon(Icons.check_circle), findsNothing);
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
    bloc.add(BusinessSearchRequested('A-12'));
    final options = await request.future;
    final cleared = bloc.stream.firstWhere(
      (state) => state is InspectionInitial,
    );
    bloc.add(BusinessSearchRequested(''));
    await cleared;
    response.complete(reply(options, {'items': [], 'has_more': false}));
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
      if (options.queryParameters['search'] == 'A-12') {
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
    bloc.add(BusinessSearchRequested('A-12'));
    final oldOptions = await oldRequest.future;
    bloc.add(BusinessSearchRequested('A-13'));
    final newOptions = await newRequest.future;
    final loaded = bloc.stream.firstWhere(
      (state) => state is InspectionSearchList,
    );
    newResponse.complete(reply(newOptions, {'items': [], 'has_more': false}));
    await loaded;
    oldResponse.complete(reply(oldOptions, {'items': [], 'has_more': false}));
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
                body: SearchBusinessBottomSheet(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Select business'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
      expect(
        tester.getBottomLeft(find.byType(ElevatedButton)).dy,
        lessThanOrEqualTo(400),
      );
    },
  );

  testWidgets(
    'unselecting a draft ordinance does not mutate the parent selection',
    (tester) async {
      final selected = [OrdinanceModel.fromJson(ordinanceResponse).toEntity()];
      final bloc = await tester.runAsync(
        () => listBloc(
          withNoShortcuts(
            (options) async => reply(options, [ordinanceResponse]),
          ),
        ),
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
      await tester.runAsync(() async {
        final loaded = bloc.stream.firstWhere(
          (state) => state is OrdinanceSelectionLoaded,
        );
        await loaded;
      });
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      await tester.tap(find.byType(OrdinanceCard));
      await tester.pump();
      expect(selected, hasLength(1));
      expect(find.byIcon(Icons.check_circle), findsNothing);
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
      final release = Completer<void>();
      var checks = 0;
      final bloc = await tester.runAsync(
        () => listBloc(
          withNoShortcuts((options) async {
            if (options.path == '/ordinance') {
              return reply(options, [ordinanceResponse]);
            }
            checks++;
            if (!request.isCompleted) request.complete(options);
            await release.future;
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            );
          }),
        ),
      );
      addTearDown(() {
        if (!release.isCompleted) release.complete();
      });
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
                  personId: 31,
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
      await tester.pump();
      await tester.runAsync(() => pumpEventQueue());
      await tester.pump(const Duration(milliseconds: 20));
      expect(request.isCompleted, isTrue);
      final options = await request.future;
      expect(options.path, '/enforcer/tickets/warning-check');
      expect(options.data['person_id'], 31);
      expect(checks, 1);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      // The selected row is locked while confirming.
      expect(cardTap(tester), isNull);
      expect(tester.takeException(), isNull);
      release.complete();
      await tester.pump();
      await tester.runAsync(() => pumpEventQueue());
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pumpAndSettle();
      expect(bloc.state, isA<WarningOrdinanceCheckError>());
      expect(checks, 1);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNotNull,
      );
      expect(cardTap(tester), isNotNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
