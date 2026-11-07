import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/features/notification/domain/entities/notification_summary.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/vendor_notification_tile.dart';

// The text the server saved for a status change has no control number and a
// blank business name.
const savedStatusText = ' — status changed from Pending to Contested.';

NotificationSummary notice({
  TicketStatus? status = TicketStatus.contested,
  String? controlNumber = '000456',
  String message = savedStatusText,
  bool isWarning = false,
}) => NotificationSummary(
  notificationId: 71,
  enforcerId: 8,
  ticketId: 42,
  controlNumber: controlNumber,
  tradeName: 'Reyes Fresh Fish',
  marketSection: 'Fish and Seafood',
  penaltyType: null,
  dueDate: null,
  status: status,
  message: message,
  isRead: false,
  createdAt: DateTime.utc(2026, 11, 7),
  isWarning: isWarning,
);

Future<void> show(WidgetTester tester, NotificationSummary notification) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VendorNotificationTile(
            notification: notification,
            onRead: (_) {},
          ),
        ),
      ),
    );

void main() {
  testWidgets('status change reads from the control number, business, status', (
    tester,
  ) async {
    await show(tester, notice());
    expect(
      find.text('Ticket 000456 for Reyes Fresh Fish is now Contested.'),
      findsOneWidget,
    );
    expect(find.text(savedStatusText), findsNothing);
  });

  testWidgets('old ticket without a printed number leaves the number out', (
    tester,
  ) async {
    await show(tester, notice(controlNumber: null, status: TicketStatus.paid));
    expect(
      find.text('A ticket for Reyes Fresh Fish is now Paid.'),
      findsOneWidget,
    );
  });

  testWidgets('in-progress status is written with a space', (tester) async {
    await show(tester, notice(status: TicketStatus.inProgress));
    expect(
      find.text('Ticket 000456 for Reyes Fresh Fish is now In Progress.'),
      findsOneWidget,
    );
  });

  testWidgets('issued ticket keeps the saved server text', (tester) async {
    const issued =
        'A violation ticket (000456) was issued for Reyes Fresh Fish.';
    await show(tester, notice(status: TicketStatus.pending, message: issued));
    expect(find.text(issued), findsOneWidget);
  });

  testWidgets('warning keeps the saved server text', (tester) async {
    const issued = 'A warning (WRN-0007) was issued for Reyes Fresh Fish.';
    await show(tester, notice(status: null, message: issued, isWarning: true));
    expect(find.text(issued), findsOneWidget);
  });

  testWidgets('issued warning (saved as Pending) keeps the saved text', (
    tester,
  ) async {
    const issued = 'A warning (WRN-0007) was issued for Reyes Fresh Fish.';
    await show(
      tester,
      notice(
        status: TicketStatus.pending,
        controlNumber: 'WRN-0007',
        message: issued,
      ),
    );
    expect(find.text(issued), findsOneWidget);
  });

  testWidgets('status change on a warning says Warning, not Ticket', (
    tester,
  ) async {
    await show(tester, notice(controlNumber: 'WRN-0001'));
    expect(
      find.text('Warning WRN-0001 for Reyes Fresh Fish is now Contested.'),
      findsOneWidget,
    );
    expect(find.text('Warning status updated'), findsOneWidget);
    expect(find.text('Ticket status updated'), findsNothing);
  });

  testWidgets('a ticket whose number is not WRN- still says Ticket', (
    tester,
  ) async {
    await show(tester, notice(controlNumber: 'E2E-CN-0002'));
    expect(find.text('Ticket status updated'), findsOneWidget);
    expect(
      find.text('Ticket E2E-CN-0002 for Reyes Fresh Fish is now Contested.'),
      findsOneWidget,
    );
  });
}
