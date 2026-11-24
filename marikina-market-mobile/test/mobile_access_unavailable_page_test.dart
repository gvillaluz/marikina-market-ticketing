import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/features/layout/presentation/pages/mobile_access_unavailable_page.dart';

const message =
    'This account does not have mobile access. Log out and sign in with an enforcer account.';

Finder get seal => find.byWidgetPredicate(
  (widget) =>
      widget is Image &&
      widget.semanticLabel == 'Marikina City seal' &&
      widget.image is AssetImage &&
      (widget.image as AssetImage).assetName == 'assets/logo/org_logo.png',
);

void main() {
  testWidgets('shows the city seal above the message, 96 wide and centered', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: MobileAccessUnavailablePage()),
    );

    expect(seal, findsOneWidget);
    expect(find.text(message), findsOneWidget);
    expect(tester.getSize(seal), const Size(96, 96));
    expect(
      tester.getCenter(seal).dx,
      tester.getCenter(find.byType(Scaffold)).dx,
    );
    expect(
      tester.getBottomLeft(seal).dy,
      lessThan(tester.getTopLeft(find.text(message)).dy),
    );
  });

  testWidgets('keeps the message readable on a narrow screen with big text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(320, 480),
            textScaler: TextScaler.linear(2),
          ),
          child: MobileAccessUnavailablePage(),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(seal, findsOneWidget);
    expect(find.text(message), findsOneWidget);
  });
}
