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

const retiredVendorPaths = [
  '/vendor/dashboard',
  '/vendor/records',
  '/vendor/records/42',
  '/vendor/notifications',
  '/vendor/profile',
  '/vendor/qr',
];

void main() {
  test('vendor accounts have no mobile access from any path', () {
    final auth = account('MarketVendor');
    for (final path in [
      Routes.login,
      Routes.loginOtp,
      Routes.splash,
      ...retiredVendorPaths,
      Routes.dashboard,
      Routes.inspetions,
      Routes.tickets,
      '/ticket/42',
      Routes.newInspection,
      Routes.notifications,
      Routes.profile,
      Routes.editProfile,
      Routes.changePassword,
    ]) {
      expect(
        MobileRouteAccess.redirect(auth, path),
        Routes.mobileAccessUnavailable,
        reason: path,
      );
    }
    expect(
      MobileRouteAccess.redirect(auth, Routes.mobileAccessUnavailable),
      isNull,
    );
    expect(
      MobileRouteAccess.redirect(
        account('MarketVendor', mustChangePassword: true),
        Routes.profile,
      ),
      Routes.mobileAccessUnavailable,
    );
  });
  test('enforcers keep their pages and cannot open retired vendor paths', () {
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
    for (final path in retiredVendorPaths) {
      expect(
        MobileRouteAccess.redirect(auth, path),
        Routes.dashboard,
        reason: path,
      );
    }
  });
  test('other backend roles cannot inherit enforcer access', () {
    for (final role in ['HeadAdmin', 'AdminOfficer']) {
      final auth = account(role);
      expect(
        MobileRouteAccess.redirect(auth, Routes.dashboard),
        Routes.mobileAccessUnavailable,
      );
      expect(
        MobileRouteAccess.redirect(auth, '/vendor/dashboard'),
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
    expect(MobileRouteAccess.redirect(otp, Routes.dashboard), Routes.loginOtp);
    expect(
      MobileRouteAccess.redirect(
        account('MarketEnforcer', mustChangePassword: true),
        Routes.profile,
      ),
      Routes.mandatoryChangePassword,
    );
    expect(
      MobileRouteAccess.redirect(
        AuthChangePasswordLoading(),
        Routes.mandatoryChangePassword,
      ),
      isNull,
    );
    expect(
      MobileRouteAccess.redirect(Unauthenticated(false), Routes.profile),
      Routes.login,
    );
  });
  test('notification taps respect role and validate ticket IDs', () {
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
    for (final role in ['HeadAdmin', 'MarketVendor']) {
      expect(
        MobileRouteAccess.notificationLocation(account(role), '42'),
        isNull,
        reason: role,
      );
      expect(
        MobileRouteAccess.notificationLocation(account(role), null),
        isNull,
        reason: role,
      );
    }
    expect(
      MobileRouteAccess.notificationLocation(
        account('MarketEnforcer', mustChangePassword: true),
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
