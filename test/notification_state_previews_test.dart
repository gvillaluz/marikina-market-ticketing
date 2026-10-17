import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/domain/enums/role.dart';
import 'package:marikina_market_mobile/features/notification/data/data_sources/notification_remote_data_source.dart';
import 'package:marikina_market_mobile/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:marikina_market_mobile/features/notification/domain/use_cases/load_notifications_use_case.dart';
import 'package:marikina_market_mobile/features/notification/domain/use_cases/load_unread_count_use_case.dart';
import 'package:marikina_market_mobile/features/notification/domain/use_cases/mark_as_read_use_case.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/notification_event.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/notification_state.dart';
import 'package:marikina_market_mobile/features/notification/presentation/pages/notification_page.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/notification_notice.dart';
import 'features/auth/data/login_mobile_contract_test.dart'
    show contractClient, reply;
import 'notification_ui_test.dart' show notificationResponse;
import 'vendor_notifications_test.dart' show vendorWarning;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  for (final isVendor in [false, true]) {
    for (final stateName in ['loaded', 'loading', 'empty', 'error']) {
      for (final (width, scale) in [(390.0, 1.0), (280.0, 2.0)]) {
        final role = isVendor ? 'vendor' : 'enforcer';
        testWidgets(
          '$role $stateName at ${width.toInt()}px and ${scale.toInt()}x text',
          (tester) async {
            tester.view.physicalSize = Size(width, 844);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            const font = String.fromEnvironment('NOTIFICATION_UI_PREVIEW_FONT');
            const previewDirectory = String.fromEnvironment(
              'NOTIFICATION_UI_PREVIEW_DIRECTORY',
              defaultValue: 'evidence/notification-ui-typography',
            );
            late NotificationBloc bloc;
            late Completer<void> gate;
            await tester.runAsync(() async {
              gate = Completer<void>();
              if (font.isNotEmpty) {
                await (FontLoader('Roboto')..addFont(
                      File(font).readAsBytes().then(ByteData.sublistView),
                    ))
                    .load();
                await (FontLoader('MaterialIcons')..addFont(
                      rootBundle.load('fonts/MaterialIcons-Regular.otf'),
                    ))
                    .load();
              }
              final client = contractClient((options) async {
                if (stateName == 'loading') await gate.future;
                if (stateName == 'error') {
                  throw DioException(
                    requestOptions: options,
                    type: DioExceptionType.badResponse,
                    response: Response<Object?>(
                      requestOptions: options,
                      statusCode: 503,
                      data: {
                        'message':
                            'Notifications are temporarily unavailable. Please try again.',
                      },
                    ),
                  );
                }
                final unreadOnly =
                    options.queryParameters['filter'] == 'Unread';
                final items = stateName == 'empty'
                    ? <Map<String, Object?>>[]
                    : [
                        if (isVendor) vendorWarning else notificationResponse,
                        if (!unreadOnly)
                          {
                            ...notificationResponse,
                            'id': 72,
                            'type': 'Ticket',
                            'status': 'Paid',
                            'is_read': true,
                            'message': 'Ticket TKT-2026-0042 is now Paid.',
                          },
                      ];
                return reply(options, {
                  'items': items,
                  'has_more': false,
                  'total': stateName == 'empty'
                      ? 0
                      : unreadOnly
                      ? 1
                      : 2,
                });
              });
              addTearDown(client.dio.close);
              final repository = NotificationRepositoryImpl(
                NotificationRemoteDataSourceImpl(
                  client,
                  role: isVendor ? Role.marketVendor : Role.marketEnforcer,
                ),
              );
              bloc = NotificationBloc(
                loadNotificationsUseCase: LoadNotificationsUseCase(repository),
                markAsReadUseCase: MarkAsReadUseCase(repository),
                loadUnreadCountUseCase: isVendor
                    ? LoadUnreadCountUseCase(repository)
                    : null,
              );
              addTearDown(() async {
                if (!gate.isCompleted) gate.complete();
                if (!bloc.isClosed) unawaited(bloc.close());
              });
              final ready = bloc.stream.firstWhere(
                (state) => stateName == 'loading'
                    ? state is NotificationLoading
                    : stateName == 'error'
                    ? state is NotificationFailed
                    : state is NotificationLoaded,
              );
              bloc.add(LoadNotifications(0, 'All'));
              await ready;
            });
            final boundaryKey = GlobalKey();
            await tester.pumpWidget(
              MaterialApp(
                theme: font.isEmpty
                    ? AppTheme.light
                    : AppTheme.light.copyWith(
                        appBarTheme: AppTheme.light.appBarTheme.copyWith(
                          titleTextStyle: AppTheme
                              .light
                              .appBarTheme
                              .titleTextStyle
                              ?.copyWith(fontFamily: 'Roboto'),
                        ),
                      ),
                home: MediaQuery(
                  data: MediaQueryData(
                    size: Size(width, 844),
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true,
                  ),
                  child: RepaintBoundary(
                    key: boundaryKey,
                    child: BlocProvider.value(
                      value: bloc,
                      child: NotificationPage(isVendor: isVendor),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
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
                  '$previewDirectory/$role-$stateName-${width.toInt()}-${scale.toInt()}x.png',
                ).writeAsBytes(bytes!.buffer.asUint8List());
                capture.dispose();
              });
            }
            if (stateName == 'loading') {
              final card = find.byKey(
                const ValueKey('notification-skeleton-card-0'),
              );
              expect(tester.getSize(card).width, width - (isVendor ? 26 : 40));
              expect(tester.getSize(card).height, greaterThan(100 * scale));
              await tester.runAsync(() async {
                gate.complete();
              });
              for (
                var attempt = 0;
                bloc.state is! NotificationLoaded && attempt < 20;
                attempt++
              ) {
                await tester.pump();
                await tester.runAsync(
                  () => Future<void>.delayed(const Duration(milliseconds: 1)),
                );
              }
              expect(bloc.state, isA<NotificationLoaded>());
            } else if (stateName == 'empty' || stateName == 'error') {
              await tester.scrollUntilVisible(
                find.byType(NotificationNotice),
                120,
              );
              expect(
                tester.getSize(find.byType(NotificationNotice)).width,
                width - 40,
              );
              expect(
                find.text(
                  stateName == 'empty'
                      ? 'No notifications'
                      : 'Notifications unavailable',
                ),
                findsOneWidget,
              );
              if (stateName == 'error') {
                expect(find.text('Try again'), findsOneWidget);
              }
            } else {
              await tester.scrollUntilVisible(
                find.text('All notifications loaded'),
                160,
              );
              expect(find.text('All notifications loaded'), findsOneWidget);
            }
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox());
          },
        );
      }
    }
  }
}
