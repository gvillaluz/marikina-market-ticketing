import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/profile_photo_options.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/submit_confirmation_bottom_sheet.dart';

Widget sheet(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void main() {
  // The theme's drag handle already leaves air above a sheet's content, so
  // the content must start at the top edge of its own area.
  testWidgets('profile photo menu starts at the top, under the drag handle', (
    tester,
  ) async {
    await tester.pumpWidget(
      sheet(
        const Align(
          alignment: Alignment.topCenter,
          child: ProfilePhotoOptions(hasPhoto: false),
        ),
      ),
    );
    expect(tester.getTopLeft(find.text('Profile photo')).dy, 0);
  });

  testWidgets('submit confirmation starts at the top and keeps its heading '
      'and subtitle close together', (tester) async {
    await tester.pumpWidget(
      sheet(
        Align(
          alignment: Alignment.topCenter,
          child: SubmitConfirmationBottomSheet(
            onPressed: () {},
            isTicket: false,
          ),
        ),
      ),
    );
    final title = find.text('Confirm warning submission');
    final subtitle = find.text(
      'Review the details before issuing this inspection record.',
    );
    expect(tester.getTopLeft(title).dy, 0);
    expect(
      tester.getTopLeft(subtitle).dy - tester.getBottomLeft(title).dy,
      closeTo(AppTheme.inspectionTinyGap, 0.01),
    );
  });
}
