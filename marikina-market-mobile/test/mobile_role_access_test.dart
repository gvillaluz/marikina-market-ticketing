import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/router/mobile_route_access.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/features/auth/data/models/user_model.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/data/login_mobile_contract_test.dart'
    show profileResponse;

Authenticated account(String role, {bool mustChangePassword = false}) =>
    Authenticated(
      user: UserModel.fromJson({
        ...profileResponse,
        'role': role,
        'mustChangedPassword': mustChangePassword,
      }).toEntity(),
    );

void main() {
  test('vendors land on their dashboard after authentication', () {
    final auth = account('MarketVendor');
    for (final path in [Routes.login, Routes.loginOtp, Routes.splash]) {
      expect(MobileRouteAccess.redirect(auth, path), Routes.vendorDashboard);
    }
  });
  test(
    'vendor access includes approved vendor pages and rejects enforcer pages',
    () {
      final auth = account('MarketVendor');
      for (final path in [
        Routes.vendorDashboard,
        Routes.vendorRecords,
        Routes.vendorNotifications,
        Routes.vendorProfile,
        Routes.vendorQr,
        Routes.editProfile,
        Routes.changePassword,
        '/vendor/records/42',
      ]) {
        expect(MobileRouteAccess.redirect(auth, path), isNull);
      }
      for (final path in [
        Routes.dashboard,
        Routes.inspetions,
        Routes.tickets,
        '/ticket/42',
        Routes.newInspection,
        Routes.newInspectionPreview,
        Routes.notifications,
        Routes.profile,
      ]) {
        expect(MobileRouteAccess.redirect(auth, path), Routes.vendorDashboard);
      }
    },
  );
  test('enforcers keep their pages and cannot open vendor routes', () {
    final auth = account('MarketEnforcer');
    expect(MobileRouteAccess.redirect(auth, Routes.login), Routes.dashboard);
    for (final path in [
      Routes.dashboard,
      Routes.inspetions,
      Routes.tickets,
      '/ticket/42',
      Routes.notifications,
      Routes.profile,
    ]) {
      expect(MobileRouteAccess.redirect(auth, path), isNull);
    }
    expect(
      MobileRouteAccess.redirect(auth, Routes.vendorRecords),
      Routes.dashboard,
    );
  });
  test('other backend roles cannot inherit enforcer or vendor access', () {
    for (final role in ['HeadAdmin', 'AdminOfficer']) {
      final auth = account(role);
      expect(
        MobileRouteAccess.redirect(auth, Routes.dashboard),
        Routes.mobileAccessUnavailable,
      );
      expect(
        MobileRouteAccess.redirect(auth, Routes.vendorDashboard),
        Routes.mobileAccessUnavailable,
      );
      expect(
        MobileRouteAccess.redirect(auth, Routes.mobileAccessUnavailable),
        isNull,
      );
    }
  });
  test('OTP and mandatory password changes precede role navigation', () {
    final otp = LoginOtpPending(
      maskedEmail: 'e***@example.com',
      resendCooldownSeconds: 30,
      codeExpirySeconds: 600,
    );
    expect(
      MobileRouteAccess.redirect(otp, Routes.vendorDashboard),
      Routes.loginOtp,
    );
    for (final role in ['MarketEnforcer', 'MarketVendor']) {
      expect(
        MobileRouteAccess.redirect(
          account(role, mustChangePassword: true),
          Routes.vendorProfile,
        ),
        Routes.mandatoryChangePassword,
      );
    }
    expect(
      MobileRouteAccess.redirect(
        AuthChangePasswordLoading(),
        Routes.mandatoryChangePassword,
      ),
      isNull,
    );
    expect(
      MobileRouteAccess.redirect(Unauthenticated(false), Routes.vendorProfile),
      Routes.login,
    );
  });
  test('notification taps respect role and validate ticket IDs', () {
    expect(
      MobileRouteAccess.notificationLocation(account('MarketVendor'), '42'),
      Routes.vendorNotifications,
    );
    expect(
      MobileRouteAccess.notificationLocation(account('MarketEnforcer'), '42'),
      '/ticket/42',
    );
    expect(
      MobileRouteAccess.notificationLocation(
        account('MarketEnforcer'),
        '../profile',
      ),
      Routes.notifications,
    );
    expect(
      MobileRouteAccess.notificationLocation(account('MarketEnforcer'), '-1'),
      Routes.notifications,
    );
    expect(
      MobileRouteAccess.notificationLocation(account('HeadAdmin'), '42'),
      isNull,
    );
    expect(
      MobileRouteAccess.notificationLocation(
        account('MarketVendor', mustChangePassword: true),
        '42',
      ),
      isNull,
    );
    expect(
      MobileRouteAccess.notificationLocation(Unauthenticated(false), '42'),
      isNull,
    );
  });
}
