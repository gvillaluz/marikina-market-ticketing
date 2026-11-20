import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/features/auth/domain/enums/role.dart';
import 'package:marikina_market_mobile/features/notification/domain/entities/notification_summary.dart';
import 'package:marikina_market_mobile/features/auth/data/models/user_model.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/notification_tile.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/profile_header_card.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/penalty_details_section.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_penalty_detail.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_status_badge.dart';
import 'features/profile/profile_contract_test.dart' show profileResponse;

Widget wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  test('role codes have spaced labels', () {
    expect(Role.headAdmin.label, 'Head Admin');
    expect(Role.adminOfficer.label, 'Admin Officer');
    expect(Role.marketEnforcer.label, 'Market Enforcer');
    expect(Role.marketVendor.label, 'Market Vendor');
  });

  testWidgets('profile header shows Head Admin, not HeadAdmin', (tester) async {
    final user = UserModel.fromJson({
      ...profileResponse,
      'role': 'HeadAdmin',
    }).toEntity();
    await tester.pumpWidget(
      wrap(
        ProfileHeaderCard(
          user: user,
          onChangePhoto: (_) {},
          onRemovePhoto: () {},
        ),
      ),
    );
    expect(find.text('Head Admin'), findsOneWidget);
    expect(find.text('HeadAdmin'), findsNothing);
  });

  testWidgets('inspection preview shows Blood Donation, not BloodDonation', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const PenaltyDetailsSection(
          severity: Severity.minor,
          penaltyType: PenaltyType.bloodDonation,
          totalFineAmount: 1000,
          communityHrs: null,
        ),
      ),
    );
    expect(find.text('Blood Donation'), findsOneWidget);
    expect(find.text('BloodDonation'), findsNothing);
  });

  testWidgets('ticket status badge shows In Progress, not InProgress', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const TicketStatusBadge(status: TicketStatus.inProgress)),
    );
    expect(find.text('In Progress'), findsOneWidget);
    expect(find.text('InProgress'), findsNothing);
  });

  testWidgets('penalty detail shows Cash Fine, not CashFine', (tester) async {
    await tester.pumpWidget(
      wrap(
        TicketPenaltyDetail(
          severity: Severity.minor,
          penaltyType: PenaltyType.cashFine,
          totalFineAmount: 1000,
          dueDate: DateTime(2026, 11, 25),
        ),
      ),
    );
    expect(find.text('Cash Fine'), findsOneWidget);
    expect(find.text('CashFine'), findsNothing);
  });

  testWidgets('community service penalty keeps the hours line', (tester) async {
    await tester.pumpWidget(
      wrap(
        TicketPenaltyDetail(
          severity: Severity.minor,
          penaltyType: PenaltyType.communityService,
          totalFineAmount: 1000,
          dueDate: DateTime(2026, 11, 25),
          communityHrs: 2,
        ),
      ),
    );
    expect(find.text('Community Service\n(2 hrs)'), findsOneWidget);
  });

  testWidgets('notification says In Progress, not InProgress', (tester) async {
    final notice = NotificationSummary(
      notificationId: 90,
      enforcerId: 8,
      ticketId: 42,
      controlNumber: '000456',
      tradeName: 'Reyes Fresh Fish',
      marketSection: 'Fish and Seafood',
      penaltyType: null,
      dueDate: null,
      status: TicketStatus.inProgress,
      message: ' — status changed to In Progress.',
      isRead: true,
      createdAt: DateTime.utc(2026, 11, 7),
      isWarning: false,
    );
    await tester.pumpWidget(
      wrap(NotificationTile(notification: notice, onRead: (_) {})),
    );
    expect(
      find.text('Ticket 000456 for Reyes Fresh Fish is now In Progress.'),
      findsOneWidget,
    );
    expect(find.textContaining('InProgress'), findsNothing);
  });
}
