import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_primary_btn.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_outlined_btn.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/skeleton_pulse.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/skeleton_box.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/profile_page_skeleton.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/notification_list_skeleton.dart';
import 'package:marikina_market_mobile/features/notification/presentation/widgets/notification_skeleton_card.dart';

Future<void> showUi(
  WidgetTester tester,
  Widget child, {
  bool reduceMotion = false,
  bool tickerEnabled = true,
  double textScale = 1,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light,
    home: MediaQuery(
      data: MediaQueryData(
        disableAnimations: reduceMotion,
        textScaler: TextScaler.linear(textScale),
      ),
      child: TickerMode(
        enabled: tickerEnabled,
        child: Scaffold(body: child),
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'reduced-motion outlined loading exposes valid progress semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await showUi(
          tester,
          AppOutlinedBtn(
            label: 'Save changes',
            iconData: Icons.save,
            onPressed: () {},
            foregroundColor: AppTheme.light.colorScheme.primary,
            backgroundColor: AppTheme.light.colorScheme.surface,
            isLoading: true,
          ),
          reduceMotion: true,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final data = tester
            .getSemantics(find.byType(CircularProgressIndicator))
            .getSemanticsData();
        expect(
          data.label.split('\n'),
          containsAll(['Loading', 'Save changes']),
        );
        expect(double.tryParse(data.value), inInclusiveRange(0, 100));
        await tester.pumpWidget(const SizedBox());
      } finally {
        semantics.dispose();
      }
    },
  );
  for (final outlined in [false, true]) {
    testWidgets(
      '${outlined ? "outlined" : "primary"} button blocks duplicate taps while loading and supports disabled state',
      (tester) async {
        var taps = 0;
        Widget button({required bool loading, bool disabled = false}) {
          if (outlined) {
            return AppOutlinedBtn(
              label: 'Save changes',
              iconData: Icons.save,
              foregroundColor: AppTheme.light.colorScheme.primary,
              backgroundColor: AppTheme.light.colorScheme.surface,
              onPressed: disabled ? null : () => taps++,
              isLoading: loading,
            );
          }
          return AppPrimaryButton(
            label: 'Save changes',
            iconData: Icons.save,
            onPressed: disabled ? null : () => taps++,
            isLoading: loading,
          );
        }

        await showUi(tester, button(loading: false));
        await tester.tap(find.text('Save changes'));
        expect(taps, 1);
        final normalSize = tester.getSize(
          find.byType(outlined ? OutlinedButton : ElevatedButton),
        );
        await showUi(tester, button(loading: true), reduceMotion: true);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save changes'));
        expect(taps, 1);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(
          tester.getSize(
            find.byType(outlined ? OutlinedButton : ElevatedButton),
          ),
          normalSize,
        );
        await showUi(tester, button(loading: false, disabled: true));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save changes'));
        expect(taps, 1);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        await showUi(tester, button(loading: false));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save changes'));
        expect(taps, 2);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('shared controls wrap long labels with large text at 280px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(280, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await showUi(
      tester,
      Padding(
        padding: AppTheme.profilePagePadding,
        child: Column(
          children: [
            AppPrimaryButton(
              label: 'Submit inspection for review',
              iconData: Icons.check,
              onPressed: () {},
            ),
            AppOutlinedBtn(
              label: 'Change account password',
              iconData: Icons.lock,
              onPressed: null,
              foregroundColor: AppTheme.light.colorScheme.primary,
              backgroundColor: AppTheme.light.colorScheme.surface,
            ),
          ],
        ),
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'inactive skeleton pauses and resumes when its tab becomes active',
    (tester) async {
      await showUi(tester, const SkeletonBox(height: 80), tickerEnabled: false);
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
      await showUi(tester, const SkeletonBox(height: 80));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.hasScheduledFrame, isTrue);
      final activeOpacity = tester
          .widget<FadeTransition>(find.byType(FadeTransition).last)
          .opacity
          .value;
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        tester
            .widget<FadeTransition>(find.byType(FadeTransition).last)
            .opacity
            .value,
        isNot(activeOpacity),
      );
      await showUi(tester, const SkeletonBox(height: 80), tickerEnabled: false);
      await tester.pumpAndSettle();
      final stoppedOpacity = tester
          .widget<FadeTransition>(find.byType(FadeTransition).last)
          .opacity
          .value;
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        tester
            .widget<FadeTransition>(find.byType(FadeTransition).last)
            .opacity
            .value,
        stoppedOpacity,
      );
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('profile pulse retains the layout widgets between frames', (
    tester,
  ) async {
    await showUi(tester, const ProfilePageSkeleton());
    final before = tester
        .widgetList<Container>(find.byType(Container))
        .toList();
    await tester.pump(const Duration(milliseconds: 200));
    final after = tester.widgetList<Container>(find.byType(Container)).toList();
    expect(after.length, before.length);
    for (var i = 0; i < before.length; i++) {
      expect(identical(after[i], before[i]), isTrue);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('notification placeholders use one pulse for the group', (
    tester,
  ) async {
    await showUi(tester, const NotificationListSkeleton());
    expect(find.byType(NotificationSkeletonCard), findsNWidgets(5));
    expect(find.byType(SkeletonPulse), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'skeleton stops scheduling frames when reduced motion is enabled',
    (tester) async {
      await showUi(tester, const SkeletonBox(height: 80));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.hasScheduledFrame, isTrue);
      await showUi(tester, const SkeletonBox(height: 80), reduceMotion: true);
      await tester.pumpAndSettle();
      final stoppedOpacity = tester
          .widget<FadeTransition>(find.byType(FadeTransition).last)
          .opacity
          .value;
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        tester
            .widget<FadeTransition>(find.byType(FadeTransition).last)
            .opacity
            .value,
        stoppedOpacity,
      );
      expect(tester.binding.hasScheduledFrame, isFalse);
      await showUi(tester, const SkeletonBox(height: 80));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.hasScheduledFrame, isTrue);
      final resumedOpacity = tester
          .widget<FadeTransition>(find.byType(FadeTransition).last)
          .opacity
          .value;
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        tester
            .widget<FadeTransition>(find.byType(FadeTransition).last)
            .opacity
            .value,
        isNot(resumedOpacity),
      );
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('profile loading layout fits a narrow screen without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(280, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await showUi(tester, const ProfilePageSkeleton(), reduceMotion: true);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
