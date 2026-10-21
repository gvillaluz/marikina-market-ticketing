import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/notification_event.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/notification_state.dart';
import 'package:marikina_market_mobile/features/notification/presentation/pages/notification_page.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/vendor_notification_tile.dart';
import 'enforcer_notifications_test.dart' show enforcerNotice, enforcerBloc;
import 'features/auth/data/login_mobile_contract_test.dart' show reply;

const capturePreviews = bool.fromEnvironment('SLICE4_PREVIEWS');

Future<void> capturePage(
  WidgetTester tester,
  double width,
  String state,
) async {
  if (!capturePreviews) return;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('preview')),
    );
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(
      '../evidence/enforcer-notification-slice-4/enforcer-${width.toInt()}-$state.png',
    ).writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    if (!capturePreviews) return;
    final sdkRoot = Platform.environment['FLUTTER_ROOT']!;
    await (FontLoader('Roboto')..addFont(
          File(
            '$sdkRoot/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
          ).readAsBytes().then(ByteData.sublistView),
        ))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  for (final width in [280.0, 400.0]) {
    testWidgets('enforcer vendor-style header, filter and mark all at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var unread = true;
      final filters = <String>[];
      late NotificationBloc bloc;
      await tester.runAsync(() async {
        bloc = enforcerBloc((options) async {
          if (options.method == 'PATCH') {
            unread = false;
            expect(options.path, '/notification/71/read');
            return reply(options, null);
          }
          final filter = options.queryParameters['filter'] as String;
          filters.add(filter);
          return reply(options, {
            'items': filter == 'Unread' && !unread
                ? []
                : [
                    {...enforcerNotice, 'is_read': !unread},
                  ],
            'total': filter == 'Unread' && !unread ? 0 : 1,
            'has_more': false,
          });
        });
        final ready = bloc.stream.firstWhere((s) => s is NotificationLoaded);
        bloc.add(LoadNotifications(0, 'All'));
        await ready;
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: RepaintBoundary(
            key: const ValueKey('preview'),
            child: BlocProvider.value(
              value: bloc,
              child: const NotificationPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsNothing);
      expect(find.text('1 unread'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Unread'), findsOneWidget);
      expect(find.byType(VendorNotificationTile), findsOneWidget);
      expect(find.text('Mark All as Read'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byType(VendorNotificationTile).first).dy -
            tester
                .getBottomLeft(
                  find.widgetWithText(TextButton, 'Mark All as Read'),
                )
                .dy,
        inInclusiveRange(0, 8),
      );
      expect(tester.takeException(), isNull);
      await capturePage(tester, width, 'loaded');
      await tester.runAsync(() async {
        final changed = bloc.stream.firstWhere(
          (s) => s is NotificationLoaded && !s.isRefreshing,
        );
        await tester.tap(find.widgetWithText(ChoiceChip, 'Unread'));
        await changed;
      });
      await tester.pumpAndSettle();
      expect(filters, contains('Unread'));
      await tester.runAsync(() async {
        var sawRefresh = false;
        final marked = bloc.stream.firstWhere((s) {
          if (s is! NotificationLoaded) return false;
          sawRefresh = sawRefresh || s.isRefreshing;
          return sawRefresh && s.unreadCount == 0 && !s.isRefreshing;
        });
        await tester.tap(find.text('Mark All as Read'));
        await marked;
      });
      await tester.pumpAndSettle();
      expect(find.text('0 unread'), findsOneWidget);
      expect(find.text('No notifications'), findsOneWidget);
      await capturePage(tester, width, 'empty');
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'Mark All as Read'),
            )
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
    'enforcer retries an initial failure and empty inbox can refresh',
    (tester) async {
      var offline = true;
      var gets = 0;
      late NotificationBloc bloc;
      await tester.runAsync(() async {
        bloc = enforcerBloc((options) async {
          gets++;
          if (offline) {
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            );
          }
          return reply(options, {'items': [], 'total': 0, 'has_more': false});
        });
        final failed = bloc.stream.firstWhere((s) => s is NotificationFailed);
        bloc.add(LoadNotifications(0, 'All'));
        await failed;
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: BlocProvider.value(
            value: bloc,
            child: const NotificationPage(),
          ),
        ),
      );
      expect(find.text('Notifications unavailable'), findsOneWidget);
      offline = false;
      await tester.runAsync(() async {
        final ready = bloc.stream.firstWhere((s) => s is NotificationLoaded);
        await tester.tap(find.text('Try again'));
        await ready;
      });
      await tester.pumpAndSettle();
      expect(find.text('0 unread'), findsOneWidget);
      expect(find.text('No notifications'), findsOneWidget);
      final before = gets;
      await tester.runAsync(
        () => tester
            .widget<RefreshIndicator>(find.byType(RefreshIndicator))
            .onRefresh(),
      );
      await tester.pumpAndSettle();
      expect(gets, before + 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('enforcer loading and pending mark all disable actions', (
    tester,
  ) async {
    final write = Completer<Response<Object?>>();
    RequestOptions? pending;
    late NotificationBloc bloc;
    await tester.runAsync(() async {
      bloc = enforcerBloc((options) async {
        if (options.method == 'PATCH') {
          pending = options;
          return write.future;
        }
        return reply(options, {
          'items': [enforcerNotice],
          'total': 1,
          'has_more': false,
        });
      });
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider.value(value: bloc, child: const NotificationPage()),
      ),
    );
    expect(find.text('Loading notifications...'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(
            find.widgetWithText(TextButton, 'Mark All as Read'),
          )
          .onPressed,
      isNull,
    );
    await tester.runAsync(() async {
      final loaded = bloc.stream.firstWhere((s) => s is NotificationLoaded);
      bloc.add(LoadNotifications(0, 'All'));
      await loaded;
    });
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final busy = bloc.stream.firstWhere(
        (s) => s is NotificationLoaded && s.isMarkingAll,
      );
      await tester.tap(find.text('Mark All as Read'));
      await busy;
      // Let the snapshot request reach the controlled HTTP write boundary.
      while (pending == null) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
    });
    await tester.pump();
    expect(find.text('Updating…'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Updating…'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, '1 unread'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<VendorNotificationTile>(find.byType(VendorNotificationTile))
          .isBusy,
      isTrue,
    );
    await tester.runAsync(() async {
      var sawRefresh = false;
      final finished = bloc.stream.firstWhere((s) {
        if (s is! NotificationLoaded) return false;
        sawRefresh = sawRefresh || s.isRefreshing;
        return sawRefresh && !s.isRefreshing;
      });
      write.complete(reply(pending!, null));
      await finished;
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('enforcer card reads and opens enforcer ticket route', (
    tester,
  ) async {
    final reads = <String>[];
    late NotificationBloc bloc;
    await tester.runAsync(() async {
      bloc = enforcerBloc((options) async {
        if (options.method == 'PATCH') {
          reads.add(options.path);
          return reply(options, null);
        }
        return reply(options, {
          'items': [enforcerNotice],
          'total': 1,
          'has_more': false,
        });
      });
      final ready = bloc.stream.firstWhere((s) => s is NotificationLoaded);
      bloc.add(LoadNotifications(0, 'All'));
      await ready;
    });
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, state) =>
              BlocProvider.value(value: bloc, child: const NotificationPage()),
        ),
        GoRoute(
          path: Routes.ticketDetail,
          name: Routes.ticketDetailName,
          builder: (_, state) => Scaffold(
            body: Text('Enforcer ticket ${state.pathParameters['ticketId']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    expect(find.byType(VendorNotificationTile), findsOneWidget);
    await tester.runAsync(() async {
      final read = bloc.stream.firstWhere(
        (s) => s is NotificationLoaded && s.notifications.single.isRead,
      );
      await tester.tap(find.byType(VendorNotificationTile));
      await read;
    });
    await tester.pumpAndSettle();
    expect(reads, ['/notification/71/read']);
    expect(find.text('Enforcer ticket 42'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
