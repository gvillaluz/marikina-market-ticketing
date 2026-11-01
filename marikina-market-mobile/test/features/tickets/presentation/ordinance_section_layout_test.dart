import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/duplicate_ordinance.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/duplicate_ticket_dialog.dart';

void main() {
  testWidgets(
    'duplicate dialog wraps section and 100 character custom category at 280px',
    (tester) async {
      tester.view.physicalSize = const Size(280, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final category = List.filled(10, 'Clearance ').join();
      final ordinance = DuplicateOrdinance(
        ordinanceId: 53,
        ordinanceNo: '11',
        section: '53',
        specificCategory: category,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: Scaffold(
              body: DuplicateTicketDialog(
                message: 'Change the selection and verify again.',
                duplicateOrdinances: [ordinance],
                onEditOrdinances: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(ordinance.detailsLabel), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
