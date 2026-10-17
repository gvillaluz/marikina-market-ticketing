import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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
import 'features/auth/data/login_mobile_contract_test.dart' show reply;
import 'vendor_notifications_test.dart' show vendorBloc, vendorWarning;

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets(
    'vendor inbox retries an initial failure to an empty, refreshable page',
    (tester) async {
      var offline = true;
      late NotificationBloc bloc;
      await tester.runAsync(() async {
        bloc = vendorBloc((options) async {
          if (offline) {
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            );
          }
          return reply(options, {'items': [], 'has_more': false, 'total': 0});
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
            child: const NotificationPage(isVendor: true),
          ),
        ),
      );
      expect(find.text('Notifications unavailable'), findsOneWidget);
      expect(
        find.text('No internet connection. Please try again.'),
        findsOneWidget,
      );
      offline = false;
      await tester.runAsync(() async {
        final ready = bloc.stream.firstWhere((s) => s is NotificationLoaded);
        await tester.tap(find.text('Try again'));
        await ready;
      });
      await tester.pumpAndSettle();
      expect(find.text('No notifications'), findsOneWidget);
      expect(find.text('0 unread'), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'Mark All as Read'),
            )
            .onPressed,
        isNull,
      );
      expect(find.byType(RefreshIndicator), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final (width, scale) in [(260.0, 1.0), (280.0, 2.0)]) {
    testWidgets(
      'vendor notification content fits width $width and text scale $scale',
      (tester) async {
        tester.view.physicalSize = Size(width, 479);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        const font = String.fromEnvironment('NOTIFICATION_PREVIEW_FONT');
        if (font.isNotEmpty) {
          await tester.runAsync(() async {
            await (FontLoader('Roboto')..addFont(
                  File(
                    font,
                  ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
                ))
                .load();
            await (FontLoader('MaterialIcons')
                  ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
                .load();
          });
        }
        final notices = [
          vendorWarning,
          {...vendorWarning, 'id': 72, 'type': 'Ticket', 'status': 'Pending'},
          {
            ...vendorWarning,
            'id': 73,
            'type': 'Ticket',
            'status': 'Overdue',
            'message': 'Pathway Obstruction is Overdue - 0312',
            'created_at': '2026-10-08T00:00:00Z',
          },
          {
            ...vendorWarning,
            'id': 74,
            'type': 'Ticket',
            'status': 'Paid',
            'is_read': true,
            'message': 'Ticket 0305 is now Paid.',
            'created_at': '2026-10-01T01:00:00Z',
          },
        ];
        late NotificationBloc bloc;
        await tester.runAsync(() async {
          bloc = vendorBloc(
            (options) async => reply(options, {
              'items': notices,
              'total': 3,
              'has_more':
                  scale == 1 && options.queryParameters['filter'] != 'Unread',
            }),
          );
          final ready = bloc.stream.firstWhere((s) => s is NotificationLoaded);
          bloc.add(LoadNotifications(0, 'All'));
          await ready;
        });
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 479),
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: RepaintBoundary(
                key: boundaryKey,
                child: BlocProvider.value(
                  value: bloc,
                  child: const NotificationPage(isVendor: true),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(AppBar), findsNothing);
        expect(find.text('Notifications'), findsOneWidget);
        expect(find.text('3 unread'), findsOneWidget);
        expect(find.text('Mark All as Read'), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (font.isNotEmpty) {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final capture = await boundary.toImage();
            final bytes = await capture.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '../evidence/phase-2-vendor-notifications/content-${width.toInt()}-${scale.toInt()}x.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            capture.dispose();
          });
        }
        for (final title in [
          'New written warning',
          'New violation ticket',
          'Ticket status updated',
          'Settlement approved',
        ]) {
          await tester.scrollUntilVisible(find.text(title), 100);
          expect(find.text(title), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'vendor tap reads the notification and opens the vendor record route',
    (tester) async {
      final reads = <String>[];
      late NotificationBloc bloc;
      await tester.runAsync(() async {
        bloc = vendorBloc((options) async {
          if (options.method == 'PATCH') {
            reads.add(options.path);
            return reply(options, null);
          }
          return reply(options, {
            'items': [vendorWarning],
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
            builder: (_, state) => BlocProvider.value(
              value: bloc,
              child: const NotificationPage(isVendor: true),
            ),
          ),
          GoRoute(
            path: Routes.vendorRecordDetail,
            name: Routes.vendorRecordDetailName,
            builder: (_, state) => Scaffold(
              body: Text('Vendor record ${state.pathParameters['ticketId']}'),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      );
      await tester.runAsync(() async {
        final read = bloc.stream.firstWhere(
          (s) => s is NotificationLoaded && s.notifications.single.isRead,
        );
        await tester.tap(find.byType(VendorNotificationTile));
        await read;
      });
      await tester.pumpAndSettle();
      expect(reads, ['/notification/vendor/71/read']);
      expect(find.text('Vendor record 11'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
