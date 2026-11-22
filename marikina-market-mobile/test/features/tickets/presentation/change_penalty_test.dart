import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/pages/ticket_detail_page.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/bloc/ticket_event.dart';

import '../../auth/data/login_mobile_contract_test.dart'
    show contractClient, reply;
import 'ticket_refresh_test.dart' show refreshBloc;

// Change penalty on an issued ticket (spec-change-penalty.md, slice 3). The real screen, bloc, repository
// and data source run; only the network is faked. Synthetic data shaped like the server's responses.
// Expected money by hand: one first offense of 200, so the cash fine is 200.00.

const _cannotPay = "Violator can't pay the cash fine";
const _asked = 'Violator asked for a different penalty';
const _wrong = 'Wrong penalty chosen when issuing';
const _noCash = 'Cash fine — not available for this ticket';
const _owner = 'You can only change the penalty on tickets you issued.';
const _stale =
    'This ticket was updated by another user. Please refresh and try again.';

class _FakeServer {
  String type = 'Ticket';
  String? status = 'Pending';
  String? penalty = 'CashFine';
  int? hours;
  List<String> allowed = ['CashFine', 'CommunityService'];
  double? cash = 200;
  (int, String)? optionsError;
  (int, String?)? changeError;
  bool unreadableOptions = false;
  bool lostAfterSave = false;
  bool failReload = false;
  Completer<void>? holdChange;
  final requests = <String>[];
  final sent = <Object?>[];

  Future<Response<Object?>> respond(RequestOptions options) async {
    requests.add('${options.method} ${options.path}');
    if (options.path.endsWith('/penalty-options')) {
      if (optionsError case (final code, final message)) {
        throw _refused(options, code, message);
      }
      return reply(
        options,
        unreadableOptions
            ? '<html>'
            : <String, dynamic>{
                'ticket_id': 85,
                'current_penalty_type': penalty,
                'allowed_penalty_types': allowed,
                'cash_fine_amount': cash,
                'community_service_hours': hours,
                'version': 5803,
              },
      );
    }
    if (options.path.endsWith('/penalty')) {
      sent.add(options.data);
      await holdChange?.future;
      if (changeError case (final code, final message)) {
        throw _refused(options, code, message);
      }
      final body = options.data as Map<String, Object?>;
      penalty = body['penalty_type'] as String;
      hours = body['community_service_hours'] as int?;
      if (lostAfterSave) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
        );
      }
      return reply(options, <String, dynamic>{
        'ticket_id': 85,
        'version': 5804,
      });
    }
    if (options.path.endsWith('/settlement/receipt')) {
      return reply(options, <String, dynamic>{
        'ticket_id': 85,
        'penalty_type': penalty,
        'proof_urls': <String>[],
      });
    }
    if (options.path.endsWith('/settlement/community-service')) {
      return reply(options, <String, dynamic>{
        'ticket_id': 85,
        'hours_required': hours,
        'hours_completed': 0,
        'hours_remaining': hours,
        'completion_percentage': 0,
        'entries': <Object?>[],
      });
    }
    if (failReload && sent.isNotEmpty) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return reply(options, <String, dynamic>{
      'ticket_id': 85,
      'enforcer_id': 1,
      'enforcer_last_name': 'Enforcer',
      'enforcer_first_name': 'Test',
      'vendor_id': null,
      'type': type,
      'status': status,
      'penalty_type': penalty,
      'total_fine_amount': penalty == 'CashFine' ? cash : null,
      'business_type': null,
      'business_account_number': null,
      'business_name': null,
      'person_id': 31,
      'person_full_name': 'Juan Cruz',
      'paper_reference': 'P4C3-0004',
      'issue_place': 'Palengke gate 2',
      'violations': <Object?>[],
      'issued_at': '2026-11-18T11:10:01Z',
      'due_date': '2026-11-23T11:10:01Z',
      'market_section_name': 'Meat and Poultry',
      'categories': <Object?>[],
      'description': 'Synthetic citation',
    });
  }

  DioException _refused(RequestOptions options, int code, String? message) =>
      DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<Object?>(
          requestOptions: options,
          statusCode: code,
          data: message == null ? '' : <String, dynamic>{'message': message},
        ),
      );
}

Future<void> _wait(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() => pumpEventQueue());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }
}

Future<void> _show(
  WidgetTester tester,
  _FakeServer server, {
  Size size = const Size(400, 900),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final bloc = (await tester.runAsync(() async {
    final client = contractClient(server.respond);
    addTearDown(client.dio.close);
    final bloc = refreshBloc(client);
    addTearDown(bloc.close);
    bloc.add(LoadTicketDetail(85));
    await pumpEventQueue();
    return bloc;
  }))!;
  await tester.pumpWidget(
    BlocProvider.value(
      value: bloc,
      child: MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: const TicketDetailPage(ticketId: 85),
      ),
    ),
  );
  await _wait(tester);
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.pump();
  await tester.tap(find.text(text).last);
  await _wait(tester);
}

Future<void> _open(WidgetTester tester) => _tap(tester, 'Change penalty');

Finder get _sheet => find.byType(BottomSheet);

Finder _inSheet(Finder finder) => find.descendant(of: _sheet, matching: finder);

Finder _button(Finder label) => find
    .ancestor(
      of: label,
      matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
    )
    .first;

bool _enabled(WidgetTester tester, String label) => tester
    .widget<ButtonStyleButton>(_button(_inSheet(find.text(label))))
    .enabled;

String _typedHours(WidgetTester tester) =>
    tester.widget<TextField>(_inSheet(find.byType(TextField))).controller!.text;

Future<void> _pickCommunityService(
  WidgetTester tester, {
  String hours = '10',
}) async {
  await _tap(tester, 'Community service');
  await tester.enterText(_inSheet(find.byType(TextField)), hours);
  await _wait(tester);
}

Future<void> _fillIn(WidgetTester tester, {String reason = _cannotPay}) async {
  await _open(tester);
  await _pickCommunityService(tester);
  await _tap(tester, reason);
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('button', () {
    for (final (status, shown) in [
      ('Pending', true),
      ('Overdue', true),
      ('Paid', false),
      ('Cleared', false),
      ('Waived', false),
      ('Contested', false),
      ('InProgress', false),
    ]) {
      testWidgets('$status: shown = $shown', (tester) async {
        await _show(tester, _FakeServer()..status = status);

        expect(find.text('PENALTY DETAILS'), findsOneWidget);
        expect(
          find.text('Change penalty'),
          shown ? findsOneWidget : findsNothing,
        );
      });
    }

    testWidgets('hidden on a warning', (tester) async {
      await _show(
        tester,
        _FakeServer()
          ..type = 'Warning'
          ..status = null
          ..penalty = null,
      );

      expect(find.text('Written Warning Record'), findsOneWidget);
      expect(find.text('Change penalty'), findsNothing);
    });

    testWidgets('is at least 48 tall', (tester) async {
      await _show(tester, _FakeServer());

      expect(
        tester.getSize(_button(find.text('Change penalty'))).height,
        greaterThanOrEqualTo(48),
      );
    });
  });

  group('choices', () {
    testWidgets('a choice that is not allowed ignores taps', (tester) async {
      await _show(tester, _FakeServer());
      await _open(tester);

      expect(find.text('Pay ₱200.00'), findsOneWidget);
      await _tap(tester, _cannotPay);
      await _tap(tester, 'Blood donation');

      expect(find.text('Select a different penalty.'), findsOneWidget);
      expect(_enabled(tester, 'Save change'), isFalse);
      expect(
        find.text(
          "Greyed choices aren't allowed for this ticket under the market code.",
        ),
        findsOneWidget,
      );
    });

    testWidgets('cash is greyed when the server does not allow it', (
      tester,
    ) async {
      await _show(
        tester,
        _FakeServer()
          ..penalty = 'CommunityService'
          ..hours = 8
          ..cash = null
          ..allowed = ['CommunityService'],
      );
      await _open(tester);

      expect(find.text(_noCash), findsOneWidget);
      await _tap(tester, _noCash);
      await _tap(tester, _wrong);

      expect(find.text('Select a different penalty.'), findsOneWidget);
      expect(_enabled(tester, 'Save change'), isFalse);
      expect(_typedHours(tester), '8');
    });

    testWidgets('current community service stays selected when not allowed', (
      tester,
    ) async {
      await _show(
        tester,
        _FakeServer()
          ..penalty = 'CommunityService'
          ..hours = 8
          ..allowed = ['CashFine'],
      );
      await _open(tester);

      expect(_typedHours(tester), '8');
      expect(find.text('Select a different penalty.'), findsOneWidget);
      await _tap(tester, 'Pay ₱200.00');
      expect(find.text('Select a reason for the change.'), findsOneWidget);
    });

    testWidgets('current blood donation stays selected when not allowed', (
      tester,
    ) async {
      await _show(
        tester,
        _FakeServer()
          ..penalty = 'BloodDonation'
          ..allowed = ['CashFine'],
      );
      await _open(tester);

      // Only the selected row is bold.
      final row = tester.widget<Text>(_inSheet(find.text('Blood donation')));
      expect(row.style!.fontWeight, FontWeight.bold);
      expect(find.text('Select a different penalty.'), findsOneWidget);
    });

    testWidgets('no greyed note when everything is allowed', (tester) async {
      await _show(
        tester,
        _FakeServer()
          ..allowed = ['CashFine', 'CommunityService', 'BloodDonation'],
      );
      await _open(tester);

      expect(find.text('Pay ₱200.00'), findsOneWidget);
      expect(find.textContaining('Greyed choices'), findsNothing);
    });
  });

  group('completeness', () {
    testWidgets('needs a different penalty and a reason', (tester) async {
      await _show(tester, _FakeServer());
      await _open(tester);

      expect(find.text('Reason for the change'), findsOneWidget);
      for (final label in [_cannotPay, _asked, _wrong]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(_enabled(tester, 'Save change'), isFalse);
      await _pickCommunityService(tester);
      expect(find.text('Select a reason for the change.'), findsOneWidget);
      expect(_enabled(tester, 'Save change'), isFalse);
      await _tap(tester, _cannotPay);
      expect(_enabled(tester, 'Save change'), isTrue);
    });

    for (final (typed, valid) in [
      ('', false),
      ('0', false),
      ('2', false),
      ('3.5', false),
      ('3', true),
      ('10', true),
    ]) {
      testWidgets('hours "$typed": valid = $valid', (tester) async {
        await _show(tester, _FakeServer());
        await _open(tester);
        await _tap(tester, _cannotPay);
        await _pickCommunityService(tester, hours: typed);

        expect(
          find.text('Enter at least 3 hours.'),
          valid ? findsNothing : findsOneWidget,
        );
        expect(_enabled(tester, 'Save change'), valid);
      });
    }

    testWidgets('hours start at 3 for a ticket that had none', (tester) async {
      await _show(tester, _FakeServer());
      await _open(tester);
      await _tap(tester, 'Community service');

      expect(_typedHours(tester), '3');
    });
  });

  group('saving', () {
    for (final (label, wire) in [
      (_cannotPay, 'CannotPayCashFine'),
      (_asked, 'RequestedDifferentPenalty'),
      (_wrong, 'WrongPenaltyAtIssue'),
    ]) {
      testWidgets('sends $wire, reloads and confirms', (tester) async {
        final server = _FakeServer();
        await _show(tester, server);
        await _fillIn(tester, reason: label);
        await _tap(tester, 'Save change');

        expect(server.sent, [
          {
            'penalty_type': 'CommunityService',
            'community_service_hours': 10,
            'reason': wire,
            'version': 5803,
          },
        ]);
        expect(server.requests, contains('PATCH /enforcer/tickets/85/penalty'));
        expect(_sheet, findsNothing);
        expect(find.byType(TicketDetailPage), findsOneWidget);
        expect(
          find.text('Penalty changed to Community service.'),
          findsOneWidget,
        );
        expect(find.text('0% of 10 hrs'), findsOneWidget);
        expect(
          server.requests.last,
          'GET /enforcer/tickets/85/settlement/community-service',
        );
      });
    }

    for (final (title, wire, done) in [
      ('Pay ₱200.00', 'CashFine', 'Cash fine'),
      ('Blood donation', 'BloodDonation', 'Blood donation'),
    ]) {
      testWidgets('to $wire sends no hours', (tester) async {
        final server = _FakeServer()
          ..penalty = 'CommunityService'
          ..hours = 10
          ..allowed = [wire, 'CommunityService'];
        await _show(tester, server);
        await _open(tester);
        await _tap(tester, title);
        await _tap(tester, _wrong);
        await _tap(tester, 'Save change');

        expect((server.sent.single as Map)['penalty_type'], wire);
        expect((server.sent.single as Map)['community_service_hours'], isNull);
        expect(find.text('Penalty changed to $done.'), findsOneWidget);
        expect(
          server.requests.last,
          'GET /enforcer/tickets/85/settlement/receipt',
        );
      });
    }

    testWidgets('cannot be closed or sent twice while saving', (tester) async {
      final server = _FakeServer()..holdChange = Completer<void>();
      await _show(tester, server);
      await _fillIn(tester);
      await _tap(tester, 'Save change');

      expect(_enabled(tester, 'Save change'), isFalse);
      expect(_enabled(tester, 'Cancel'), isFalse);
      await tester.binding.handlePopRoute();
      await _wait(tester);
      expect(_sheet, findsOneWidget);
      await tester.tapAt(const Offset(200, 5));
      await _wait(tester);
      expect(_sheet, findsOneWidget);
      await tester.dragFrom(
        tester.getTopLeft(_sheet) + const Offset(200, 10),
        const Offset(0, 500),
      );
      await _wait(tester);
      expect(_sheet, findsOneWidget);
      expect(server.sent, hasLength(1));

      server.holdChange!.complete();
      await _wait(tester);
      expect(_sheet, findsNothing);
    });

    testWidgets('a failed reload still says the change was saved', (
      tester,
    ) async {
      final server = _FakeServer()..failReload = true;
      await _show(tester, server);
      await _fillIn(tester);
      await _tap(tester, 'Save change');

      expect(_sheet, findsNothing);
      expect(
        find.text(
          'Penalty changed to Community service. No internet connection. Please try again.',
        ),
        findsOneWidget,
      );
    });
  });

  group('failures', () {
    for (final (code, message, shown) in [
      (409, _stale, _stale),
      (403, _owner, _owner),
      (502, null, 'Unable to change the penalty. Try again.'),
    ]) {
      testWidgets('$code keeps the panel open, closing reloads', (
        tester,
      ) async {
        final server = _FakeServer()..changeError = (code, message);
        await _show(tester, server);
        await _fillIn(tester);
        await _tap(tester, 'Save change');

        expect(_sheet, findsOneWidget);
        expect(find.text(shown), findsOneWidget);
        expect(
          find.text('Closing this panel reloads the ticket.'),
          findsOneWidget,
        );
        server.requests.clear();
        await _tap(tester, 'Cancel');

        expect(_sheet, findsNothing);
        expect(find.byType(TicketDetailPage), findsOneWidget);
        expect(server.requests.first, 'GET /enforcer/tickets/85');
      });
    }

    testWidgets('a change saved before the connection dropped shows on close', (
      tester,
    ) async {
      final server = _FakeServer()..lostAfterSave = true;
      await _show(tester, server);
      await _fillIn(tester);
      await _tap(tester, 'Save change');
      await tester.binding.handlePopRoute();
      await _wait(tester);

      expect(find.byType(TicketDetailPage), findsOneWidget);
      expect(find.text('0% of 10 hrs'), findsOneWidget);
    });

    testWidgets('cancel without saving does not reload', (tester) async {
      final server = _FakeServer();
      await _show(tester, server);
      await _open(tester);
      server.requests.clear();
      await _tap(tester, 'Cancel');

      expect(_sheet, findsNothing);
      expect(server.requests, isEmpty);
    });

    testWidgets('reopening starts clean', (tester) async {
      await _show(tester, _FakeServer());
      await _fillIn(tester);
      await _tap(tester, 'Cancel');
      await _open(tester);

      expect(find.text('Select a different penalty.'), findsOneWidget);
    });

    testWidgets('a refusal to load shows the reason and can be retried', (
      tester,
    ) async {
      final server = _FakeServer()..optionsError = (403, _owner);
      await _show(tester, server);
      await _open(tester);

      expect(find.text(_owner), findsOneWidget);
      expect(_inSheet(find.text('Save change')), findsNothing);
      server.optionsError = null;
      await _tap(tester, 'Retry');
      expect(find.text('Pay ₱200.00'), findsOneWidget);
    });

    for (final broken in ['not JSON', 'unknown penalty']) {
      testWidgets('an unreadable reply ($broken) is an error, not a spinner', (
        tester,
      ) async {
        final server = _FakeServer();
        if (broken == 'not JSON') {
          server.unreadableOptions = true;
        } else {
          server.allowed = ['Jail'];
        }
        await _show(tester, server);
        await _open(tester);

        expect(
          find.text('Unable to read the penalty choices. Please try again.'),
          findsOneWidget,
        );
        expect(_inSheet(find.text('Retry')), findsOneWidget);
      });
    }
  });

  group('layout', () {
    testWidgets('fits 320 wide with double-size text', (tester) async {
      await _show(
        tester,
        _FakeServer(),
        size: const Size(320, 640),
        textScale: 2,
      );
      await _open(tester);
      await _pickCommunityService(tester, hours: '2');
      await _tap(tester, _cannotPay);
      await tester.ensureVisible(_inSheet(find.text('Cancel')));
      await _wait(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('stays reachable above the keyboard', (tester) async {
      await _show(tester, _FakeServer(), size: const Size(360, 640));
      await _open(tester);
      await _tap(tester, 'Community service');
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await _wait(tester);
      await tester.ensureVisible(_inSheet(find.text('Cancel')));
      await _wait(tester);

      expect(
        tester.getBottomLeft(_inSheet(find.text('Cancel'))).dy,
        lessThanOrEqualTo(640 - 280),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('reason rows are at least 48 tall', (tester) async {
      await _show(tester, _FakeServer());
      await _open(tester);

      for (final label in [_cannotPay, _asked, _wrong]) {
        final row = find.ancestor(
          of: find.text(label),
          matching: find.byType(InkWell),
        );
        expect(tester.getSize(row.first).height, greaterThanOrEqualTo(48));
      }
    });
  });
}
