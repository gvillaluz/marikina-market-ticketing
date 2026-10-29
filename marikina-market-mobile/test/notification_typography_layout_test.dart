import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/presentation/widgets/login_otp_heading.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/edit_profile_heading.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/notification_header.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/notification_list_skeleton.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/vendor_notification_header.dart';

void main() {
  testWidgets(
    'content-sized skeletons scroll inside a bounded loading region',
    (tester) async {
      for (final isVendor in [true, false]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Scaffold(
                body: SizedBox(
                  height: 300,
                  child: NotificationListSkeleton(isVendor: isVendor),
                ),
              ),
            ),
          ),
        );
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets('account edit keeps its original size and sign-in is unchanged', (
    tester,
  ) async {
    for (final heading in [
      const EditProfileHeading(),
      const LoginOtpHeading(maskedEmail: 'v***@example.com'),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: heading),
        ),
      );
      final title = find.text(
        heading is EditProfileHeading
            ? 'Update your account information'
            : 'SIGN-IN VERIFICATION',
      );
      expect(
        tester.widget<Text>(title).style?.fontSize,
        heading is EditProfileHeading
            ? 22
            : AppTheme.authPageTitleStyle.fontSize,
      );
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('vendor page heading uses the Records title and subtitle sizes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: VendorNotificationHeader(
            unreadCount: 3,
            unreadOnly: false,
            isBusy: false,
            onToggleUnread: () {},
            onMarkAll: () {},
          ),
        ),
      ),
    );
    expect(
      tester.widget<Text>(find.text('Notifications')).style?.fontSize,
      AppTheme.inspectionTitleStyle.fontSize,
    );
    expect(
      tester
          .widget<Text>(
            find.text('Stay updated on your market inspection records.'),
          )
          .style
          ?.fontSize,
      AppTheme.inspectionBodyStyle.fontSize,
    );
  });

  testWidgets('enforcer page content exposes the same title hierarchy', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: NotificationHeader(filter: 'All', onChange: (_) {}),
        ),
      ),
    );
    expect(find.text('Notifications'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Notifications')).style?.fontSize,
      AppTheme.inspectionTitleStyle.fontSize,
    );
  });

  testWidgets(
    'notification loading cards occupy the actual list content width',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const Scaffold(
              body: SingleChildScrollView(child: NotificationListSkeleton()),
            ),
          ),
        ),
      );
      final card = find.byKey(const ValueKey('notification-skeleton-card-0'));
      expect(card, findsOneWidget);
      expect(tester.getSize(card).width, 350);
      expect(tester.getSize(card).height, greaterThan(100));
      expect(tester.takeException(), isNull);
    },
  );
}
