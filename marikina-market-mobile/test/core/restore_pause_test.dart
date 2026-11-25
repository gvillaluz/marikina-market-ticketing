import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/errors/exceptions.dart';
import 'package:marikina_market_mobile/core/network/client.dart';
import 'package:marikina_market_mobile/core/network/restore_pause_cubit.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/restore_pause_notice.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/data/data_sources/inspection_remote_data_source.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/params/save_inspection_params.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';

// The server's answers, as written by RestorePauseMiddleware and
// ExceptionHandlingMiddleware in marikina-market-api.
const pauseSentence =
    'The system is being restored. Try again in a few minutes.';
const pauseBody = <String, Object?>{
  'title': 'System restore in progress',
  'message': pauseSentence,
};
const emailProblemBody = <String, Object?>{
  'message': 'Unable to send your sign-in code. Please try again shortly.',
};

Response<Object?> answer(RequestOptions options, int status, Object? data) =>
    Response<Object?>(requestOptions: options, statusCode: status, data: data);

// A client whose server always gives [respond]'s answer. Success answers and
// refusals both travel through the client's own handling, as on a real phone.
ApiClient fakeServer(
  RestorePauseCubit pause,
  Response<Object?>? Function(RequestOptions) respond,
) {
  final client = ApiClient(onRestorePause: pause.setPaused);
  client.dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final response = respond(options);
        if (response == null) {
          return handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            ),
            true,
          );
        }
        if (response.statusCode! < 400) {
          return handler.resolve(response, true);
        }
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: response,
          ),
          true,
        );
      },
    ),
  );
  return client;
}

Future<void> ask(ApiClient client) async {
  try {
    await client.get('/enforcer/tickets/dashboard');
  } on DioException {
    // The screen's own error handling is not under test here.
  }
}

// Pages come through a router, as in the real app (AppRouter).
Widget app(RestorePauseCubit pause, Widget page, {double textScale = 1}) =>
    MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: GoRouter(
        routes: [GoRoute(path: '/', builder: (_, _) => page)],
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          padding: const EdgeInsets.only(top: 24),
        ),
        child: BlocProvider.value(
          value: pause,
          child: RestorePauseNotice(child: child!),
        ),
      ),
    );

class InspectionsPage extends StatelessWidget {
  const InspectionsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Inspections')),
    body: const Text('Sample page'),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('the phone recognises the restore pause', () {
    test('the pause answer marks the system paused', () async {
      final pause = RestorePauseCubit();
      addTearDown(pause.close);

      await ask(fakeServer(pause, (o) => answer(o, 503, pauseBody)));

      expect(pause.state, isTrue);
    });

    test('an email problem, also 503, is not a pause', () async {
      final pause = RestorePauseCubit();
      addTearDown(pause.close);

      await ask(fakeServer(pause, (o) => answer(o, 503, emailProblemBody)));

      expect(pause.state, isFalse);
    });

    test('a normal answer clears the pause', () async {
      final pause = RestorePauseCubit()..setPaused(true);
      addTearDown(pause.close);

      await ask(fakeServer(pause, (o) => answer(o, 200, <String, Object?>{})));

      expect(pause.state, isFalse);
    });

    test('any other refusal also clears the pause', () async {
      final pause = RestorePauseCubit()..setPaused(true);
      addTearDown(pause.close);

      await ask(
        fakeServer(
          pause,
          (o) => answer(o, 404, {
            'message': 'The requested record was not found.',
          }),
        ),
      );

      expect(pause.state, isFalse);
    });

    test('no answer at all leaves the pause as it was', () async {
      final pause = RestorePauseCubit()..setPaused(true);
      addTearDown(pause.close);

      await ask(fakeServer(pause, (_) => null));

      expect(pause.state, isTrue);
    });
  });

  test(
    'a ticket submitted during the pause is refused with the restore sentence, '
    'not reported as unconfirmed',
    () async {
      final pause = RestorePauseCubit();
      addTearDown(pause.close);
      final client = fakeServer(pause, (o) => answer(o, 503, pauseBody));

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
            pauseSentence,
          ),
        ),
      );
    },
  );

  group('the notice', () {
    testWidgets('shows nothing while the system runs normally', (tester) async {
      final pause = RestorePauseCubit();
      addTearDown(pause.close);

      await tester.pumpWidget(app(pause, const InspectionsPage()));

      expect(find.text(pauseSentence), findsNothing);
    });

    testWidgets(
      'appears above the page, is read out, and pushes the page down',
      (tester) async {
        final pause = RestorePauseCubit();
        addTearDown(pause.close);
        final semantics = tester.ensureSemantics();

        await tester.pumpWidget(app(pause, const InspectionsPage()));
        final barTopBefore = tester.getTopLeft(find.byType(AppBar)).dy;
        pause.setPaused(true);
        await tester.pump();

        final sentence = find.text(pauseSentence);
        expect(sentence, findsOneWidget);
        // Below the phone's clock bar (24 high in this test).
        expect(tester.getTopLeft(sentence).dy, greaterThanOrEqualTo(24));
        // The page's top bar moves below the notice instead of being covered.
        expect(
          tester.getTopLeft(find.byType(AppBar)).dy,
          greaterThanOrEqualTo(tester.getBottomLeft(sentence).dy),
        );
        expect(barTopBefore, 0);
        // The clock bar's space is not added a second time above the bar.
        expect(tester.getSize(find.byType(AppBar)).height, kToolbarHeight);
        final spoken = tester.getSemantics(sentence);
        expect(
          spoken,
          matchesSemantics(label: pauseSentence, isLiveRegion: true),
        );
        // Read out as the notice itself, not folded into the whole screen.
        expect(spoken.rect.height, tester.getSize(sentence).height);
        semantics.dispose();
      },
    );

    testWidgets('fits a narrow phone with the largest text', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final pause = RestorePauseCubit()..setPaused(true);
      addTearDown(pause.close);

      await tester.pumpWidget(
        app(pause, const InspectionsPage(), textScale: 2),
      );

      expect(tester.takeException(), isNull);
      final sentence = find.text(pauseSentence);
      expect(tester.getSize(sentence).width, lessThanOrEqualTo(320));
      expect(tester.getBottomLeft(sentence).dy, lessThan(640));
    });
  });
}
