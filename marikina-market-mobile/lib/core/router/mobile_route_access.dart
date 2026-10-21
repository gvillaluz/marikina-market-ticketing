import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/features/auth/domain/enums/role.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';

class MobileRouteAccess {
  MobileRouteAccess._();

  static const _publicRoutes = {
    Routes.login,
    Routes.findAccount,
    Routes.forgotPasswordOption,
    Routes.codeVerification,
    Routes.resetPassword,
  };
  static const _vendorRoutes = {
    Routes.vendorDashboard,
    Routes.vendorRecords,
    Routes.vendorNotifications,
    Routes.vendorProfile,
    Routes.vendorQr,
    Routes.editProfile,
    Routes.changePassword,
  };
  static const _enforcerRoutes = {
    Routes.dashboard,
    Routes.inspetions,
    Routes.tickets,
    Routes.profile,
    Routes.notifications,
    Routes.editProfile,
    Routes.changePassword,
    Routes.newInspection,
    Routes.newInspectionPreview,
  };

  static String? redirect(AuthState state, String path) {
    if (state is AuthInitial || state is AuthLoading) {
      return path == Routes.splash ? null : Routes.splash;
    }
    if (state is LoginOtpPending) {
      return path == Routes.loginOtp ? null : Routes.loginOtp;
    }
    if (state is AuthChangePasswordLoading ||
        state is AuthChangePasswordError ||
        state is AuthChangePasswordNetworkError) {
      return path == Routes.mandatoryChangePassword
          ? null
          : Routes.mandatoryChangePassword;
    }
    if (state is! Authenticated) {
      return _publicRoutes.contains(path) ? null : Routes.login;
    }
    final role = state.user.role;
    if (role != Role.marketEnforcer && role != Role.marketVendor) {
      return path == Routes.mobileAccessUnavailable
          ? null
          : Routes.mobileAccessUnavailable;
    }
    if (state.user.mustChangePassword) {
      return path == Routes.mandatoryChangePassword
          ? null
          : Routes.mandatoryChangePassword;
    }
    final allowed = role == Role.marketVendor
        ? _vendorRoutes.contains(path) ||
              RegExp(r'^/vendor/records/[^/]+$').hasMatch(path)
        : _enforcerRoutes.contains(path) ||
              RegExp(r'^/ticket/[^/]+$').hasMatch(path);
    if (allowed) return null;
    return role == Role.marketVendor
        ? Routes.vendorDashboard
        : Routes.dashboard;
  }

  static String? notificationLocation(AuthState state, Object? ticketId) {
    if (state is! Authenticated || state.user.mustChangePassword) return null;
    final id = ticketId is int
        ? ticketId
        : ticketId is String
        ? int.tryParse(ticketId)
        : null;
    final validId = id != null && id > 0 && id <= 2147483647;
    if (state.user.role == Role.marketVendor) {
      return validId ? '/vendor/records/$id' : Routes.vendorNotifications;
    }
    if (state.user.role == Role.marketEnforcer) {
      return validId ? '/ticket/$id' : Routes.notifications;
    }
    return null;
  }
}
