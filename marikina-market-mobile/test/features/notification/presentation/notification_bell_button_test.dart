import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/errors/failure.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/features/notification/domain/repositories/notification_repository.dart';
import 'package:marikina_market_mobile/features/notification/domain/use_cases/load_unread_count_use_case.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/unread_count_bloc.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/unread_count_event.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/notification_bell_button.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/notification_unread_badge.dart';

void main() {
  late _UnreadRepository repository;
  late StreamController<void> arrivals;

  setUp(() {
    repository = _UnreadRepository();
    arrivals = StreamController<void>.broadcast();
  });
  tearDown(() => arrivals.close());

  Future<void> pumpBell(WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            appBar: AppBar(actions: const [NotificationBellButton()]),
          ),
        ),
        GoRoute(
          name: Routes.notificationsName,
          path: Routes.notifications,
          builder: (_, _) => const Scaffold(body: Text('Inbox')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => UnreadCountBloc(
          loadUnreadCountUseCase: LoadUnreadCountUseCase(repository),
          notificationArrivals: arrivals.stream,
        )..add(LoadUnreadCount()),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder badge() => find.byType(NotificationUnreadBadge);

  testWidgets('no unread notifications shows no badge', (tester) async {
    repository.next = const Success(0);
    await pumpBell(tester);
    expect(badge(), findsNothing);
    expect(find.byTooltip('Notifications'), findsOneWidget);
  });

  testWidgets('unread notifications show their number', (tester) async {
    final semantics = tester.ensureSemantics();
    repository.next = const Success(3);
    await pumpBell(tester);
    expect(find.descendant(of: badge(), matching: find.text('3')), findsOne);
    // Screen readers hear the count once, from the button, not the badge.
    final button = tester.getSemantics(find.byType(IconButton));
    expect(
      button,
      isSemantics(isButton: true, tooltip: 'Notifications, 3 unread'),
    );
    expect(button.label, isEmpty);
    semantics.dispose();
  });

  testWidgets('more than 99 unread shows 99+', (tester) async {
    repository.next = const Success(150);
    await pumpBell(tester);
    expect(find.descendant(of: badge(), matching: find.text('99+')), findsOne);
    expect(find.byTooltip('Notifications, 150 unread'), findsOneWidget);
  });

  testWidgets('a count that cannot be loaded hides the badge', (tester) async {
    repository.next = const ResultFailure(NetworkFailure('Offline'));
    await pumpBell(tester);
    expect(badge(), findsNothing);
    expect(find.byTooltip('Notifications'), findsOneWidget);
  });

  testWidgets('coming back from Notifications reloads the count', (
    tester,
  ) async {
    repository.next = const Success(3);
    await pumpBell(tester);
    expect(badge(), findsOneWidget);

    await tester.tap(find.byTooltip('Notifications, 3 unread'));
    await tester.pumpAndSettle();
    expect(find.text('Inbox'), findsOneWidget);

    repository.next = const Success(0);
    final calls = repository.calls;
    GoRouter.of(tester.element(find.text('Inbox'))).pop();
    await tester.pumpAndSettle();
    expect(repository.calls, calls + 1);
    expect(badge(), findsNothing);
  });

  testWidgets('a new notification while open reloads the count', (
    tester,
  ) async {
    repository.next = const Success(1);
    await pumpBell(tester);
    expect(find.descendant(of: badge(), matching: find.text('1')), findsOne);

    repository.next = const Success(2);
    arrivals.add(null);
    await tester.pumpAndSettle();
    expect(find.descendant(of: badge(), matching: find.text('2')), findsOne);
  });

  testWidgets('returning to the app reloads the count', (tester) async {
    repository.next = const Success(0);
    await pumpBell(tester);
    expect(badge(), findsNothing);

    repository.next = const Success(4);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.descendant(of: badge(), matching: find.text('4')), findsOne);
  });

  test('an older answer cannot overwrite a newer one', () async {
    final slow = Completer<Result<int>>();
    final fast = Completer<Result<int>>();
    final answers = [slow, fast];
    final repository = _UnreadRepository()
      ..load = () => answers.removeAt(0).future;
    final bloc = UnreadCountBloc(
      loadUnreadCountUseCase: LoadUnreadCountUseCase(repository),
      notificationArrivals: const Stream.empty(),
    );
    addTearDown(bloc.close);

    bloc
      ..add(LoadUnreadCount())
      ..add(LoadUnreadCount());
    await Future<void>.delayed(Duration.zero);
    fast.complete(const Success(5));
    await bloc.stream.firstWhere((state) => state.count == 5);
    slow.complete(const Success(9));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.count, 5);
  });
}

class _UnreadRepository extends Fake implements NotificationRepository {
  Result<int> next = const Success(0);
  Future<Result<int>> Function()? load;
  int calls = 0;

  @override
  Future<Result<int>> loadUnreadCount() async {
    calls++;
    final load = this.load;
    return load == null ? next : await load();
  }
}
