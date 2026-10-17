import 'package:marikina_market_mobile/features/auth/domain/enums/role.dart';
import 'package:marikina_market_mobile/features/profile/presentation/pages/vendor_qr_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/di/dependency_injection.dart';
import 'package:marikina_market_mobile/core/router/route_args.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/records/presentation/pages/records_page.dart';
import 'package:marikina_market_mobile/features/records/presentation/bloc/vendor_settlement/vendor_settlement_bloc.dart';
import 'package:marikina_market_mobile/features/records/presentation/pages/vendor_ticket_detail_page.dart';
import 'package:marikina_market_mobile/features/records/presentation/bloc/records/records_bloc.dart';
import 'package:marikina_market_mobile/features/records/presentation/bloc/records/load_records.dart';
import 'package:marikina_market_mobile/features/records/presentation/bloc/record_detail/record_detail_bloc.dart';
import 'package:marikina_market_mobile/features/records/presentation/bloc/record_detail/load_record_detail.dart';
import 'package:marikina_market_mobile/features/layout/presentation/widgets/root_branch_container.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:marikina_market_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:marikina_market_mobile/features/auth/presentation/pages/login_otp_page.dart';
import 'package:marikina_market_mobile/features/auth/presentation/pages/mandatory_change_password_page.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/pages/vendor_dashboard_page.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/bloc/vendor_dashboard_bloc.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/bloc/load_vendor_dashboard.dart';
import 'package:marikina_market_mobile/features/layout/presentation/pages/root_screen.dart';
import 'package:marikina_market_mobile/features/layout/presentation/pages/mobile_access_unavailable_page.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/notification_event.dart';
import 'package:marikina_market_mobile/features/notification/presentation/pages/notification_page.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/bloc/password_recovery_bloc.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/pages/code_validation_page.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/pages/find_account_page.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/pages/forgot_password_option_page.dart';
import 'package:marikina_market_mobile/features/password_recovery/presentation/pages/reset_password_page.dart';
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:marikina_market_mobile/features/profile/presentation/pages/change_password_page.dart';
import 'package:marikina_market_mobile/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:marikina_market_mobile/features/profile/presentation/pages/profile_page.dart';
import 'package:marikina_market_mobile/features/splash/presentation/pages/splash_screen.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/duplicate_ordinance.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/inspection_form_data.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/pages/add_new_inspection_page.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/pages/inspections_page.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/pages/new_inspection_preview_page.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/pages/ticket_detail_page.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/bloc/ticket_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/bloc/ticket_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/pages/tickets_page.dart';

final appRoutes = buildAppRoutes();

List<RouteBase> buildAppRoutes({String? sessionKey}) => [
  GoRoute(
    name: Routes.loginOtpName,
    path: Routes.loginOtp,
    pageBuilder: (context, state) =>
        CupertinoPage(key: state.pageKey, child: const LoginOtpPage()),
  ),
  GoRoute(
    name: Routes.loginName,
    path: Routes.login,
    pageBuilder: (context, state) =>
        _fadePage(context, state, key: state.pageKey, child: const LoginPage()),
  ),
  GoRoute(
    name: Routes.mandatoryChangePasswordName,
    path: Routes.mandatoryChangePassword,
    pageBuilder: (context, state) => _fadePage(
      context,
      state,
      key: ValueKey((state.pageKey, sessionKey)),
      child: const MandatoryChangePasswordPage(),
    ),
  ),
  GoRoute(
    name: Routes.findAccountName,
    path: Routes.findAccount,
    pageBuilder: (context, state) => _fadePage(
      context,
      state,
      key: state.pageKey,
      child: BlocProvider(
        create: (_) => sl<PasswordRecoveryBloc>(),
        child: const FindAccountPage(),
      ),
    ),
  ),
  GoRoute(
    name: Routes.forgotPasswordOptionName,
    path: Routes.forgotPasswordOption,
    pageBuilder: (context, state) {
      final extra = state.extra as ForgotPasswordOptionArgs;

      return _fadePage(
        context,
        state,
        key: state.pageKey,
        child: BlocProvider(
          create: (_) => sl<PasswordRecoveryBloc>(),
          child: ForgotPasswordOptionPage(args: extra),
        ),
      );
    },
  ),
  GoRoute(
    name: Routes.codeVerificationName,
    path: Routes.codeVerification,
    pageBuilder: (context, state) {
      final extra = state.extra as CodeValidationArgs;
      return _fadePage(
        context,
        state,
        key: state.pageKey,
        child: BlocProvider(
          create: (_) => sl<PasswordRecoveryBloc>(),
          child: CodeValidationPage(args: extra),
        ),
      );
    },
  ),
  GoRoute(
    name: Routes.resetPasswordName,
    path: Routes.resetPassword,
    pageBuilder: (context, state) {
      final extra = state.extra as ResetPasswordArgs;

      return _fadePage(
        context,
        state,
        key: state.pageKey,
        child: BlocProvider(
          create: (_) => sl<PasswordRecoveryBloc>(),
          child: ResetPasswordPage(args: extra),
        ),
      );
    },
  ),
  GoRoute(
    name: Routes.splashName,
    path: Routes.splash,
    pageBuilder: (context, state) => _fadePage(
      context,
      state,
      key: state.pageKey,
      child: const SplashScreen(),
    ),
  ),
  GoRoute(
    name: Routes.ticketDetailName,
    path: Routes.ticketDetail,
    redirect: (context, state) {
      final ticketId = int.tryParse(state.pathParameters['ticketId'] ?? '');

      if (ticketId == null) return Routes.inspectionsName;

      return null;
    },
    pageBuilder: (context, state) {
      final ticketId = int.tryParse(state.pathParameters['ticketId'] ?? '');
      final droppedOrdinances = state.extra != null
          ? (state.extra as List).cast<DuplicateOrdinance>()
          : null;

      return CupertinoPage(
        key: state.pageKey,
        child: BlocProvider(
          create: (_) => sl<TicketBloc>()..add(LoadTicketDetail(ticketId!)),
          child: TicketDetailPage(
            ticketId: ticketId,
            droppedOrdinances: droppedOrdinances,
          ),
        ),
      );
    },
  ),
  GoRoute(
    name: Routes.vendorQrName,
    path: Routes.vendorQr,
    builder: (context, state) {
      final auth = context.read<AuthBloc>().state;
      if (auth is! Authenticated) return const SizedBox.shrink();
      return BlocProvider(
        create: (_) => sl<ProfileBloc>(instanceName: 'vendorProfile'),
        child: VendorQrPage(user: auth.user),
      );
    },
  ),
  GoRoute(
    name: Routes.editProfileName,
    path: Routes.editProfile,
    pageBuilder: (context, state) {
      final auth = context.read<AuthBloc>().state as Authenticated;
      final user = auth.user;

      return CupertinoPage(
        key: state.pageKey,
        child: BlocProvider(
          create: (_) => sl<ProfileBloc>(
            instanceName: user.role == Role.marketVendor
                ? 'vendorProfile'
                : null,
          ),
          child: EditProfilePage(user: user),
        ),
      );
    },
  ),
  GoRoute(
    name: Routes.changePasswordName,
    path: Routes.changePassword,
    pageBuilder: (context, state) {
      final user = (context.read<AuthBloc>().state as Authenticated).user;

      return CupertinoPage(
        key: state.pageKey,
        child: BlocProvider(
          create: (_) => sl<ProfileBloc>(),
          child: ChangePasswordPage(user: user),
        ),
      );
    },
  ),
  GoRoute(
    name: Routes.newInspectionName,
    path: Routes.newInspection,
    pageBuilder: (context, state) {
      final authState = sl<AuthBloc>().state;

      final user = (authState as Authenticated).user;

      return CupertinoPage(
        key: state.pageKey,
        child: BlocProvider(
          create: (_) => sl<InspectionBloc>(),
          child: AddNewInspectionPage(user: user),
        ),
      );
    },
    routes: [
      GoRoute(
        name: Routes.newInspectionPreviewName,
        path: Routes.newInspectionPreview,
        pageBuilder: (context, state) {
          final formData = state.extra as InspectionFormData;

          return CupertinoPage(
            key: state.pageKey,
            child: BlocProvider(
              create: (_) => sl<InspectionBloc>(),
              child: NewInspectionPreviewPage(formData: formData),
            ),
          );
        },
      ),
    ],
  ),
  GoRoute(
    name: Routes.notificationsName,
    path: Routes.notifications,
    pageBuilder: (context, state) {
      return CupertinoPage(
        key: state.pageKey,
        child: BlocProvider(
          create: (_) =>
              sl<NotificationBloc>()..add(LoadNotifications(0, 'All')),
          child: const NotificationPage(),
        ),
      );
    },
  ),
  StatefulShellRoute(
    builder: (context, state, navigationShell) =>
        RootScreen(navigationShell: navigationShell),

    navigatorContainerBuilder: (context, navigationShell, children) =>
        RootBranchContainer(
          currentIndex: navigationShell.currentIndex,
          children: children,
        ),
    branches: _buildEnforcerBranches(),
  ),
  GoRoute(
    path: Routes.mobileAccessUnavailable,
    builder: (context, state) => const MobileAccessUnavailablePage(),
  ),
  GoRoute(
    name: Routes.vendorRecordDetailName,
    path: Routes.vendorRecordDetail,
    redirect: (context, state) {
      final id = int.tryParse(state.pathParameters['ticketId'] ?? '');
      return id == null || id <= 0 || id > 2147483647
          ? Routes.vendorRecords
          : null;
    },
    pageBuilder: (context, state) {
      final id = int.parse(state.pathParameters['ticketId']!);
      return CupertinoPage(
        key: state.pageKey,
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => sl<RecordDetailBloc>()..add(LoadRecordDetail(id)),
            ),
            BlocProvider(create: (_) => sl<VendorSettlementBloc>()),
          ],
          child: VendorTicketDetailPage(ticketId: id),
        ),
      );
    },
  ),
  StatefulShellRoute(
    builder: (context, state, navigationShell) =>
        RootScreen(navigationShell: navigationShell, isVendor: true),
    navigatorContainerBuilder: (context, navigationShell, children) =>
        RootBranchContainer(
          currentIndex: navigationShell.currentIndex,
          children: children,
        ),
    branches: [
      for (final (path, name) in [
        (Routes.vendorDashboard, Routes.vendorDashboardName),
        (Routes.vendorRecords, Routes.vendorRecordsName),
        (Routes.vendorNotifications, Routes.vendorNotificationsName),
        (Routes.vendorProfile, Routes.vendorProfileName),
      ])
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: path,
              name: name,
              builder: (context, state) => path == Routes.vendorRecords
                  ? BlocProvider(
                      create: (_) =>
                          sl<RecordsBloc>()..add(const LoadRecords()),
                      child: const RecordsPage(),
                    )
                  : path == Routes.vendorNotifications
                  ? BlocProvider(
                      create: (_) => sl<NotificationBloc>(
                        instanceName: 'vendorNotifications',
                      )..add(LoadNotifications(0, 'All')),
                      child: const NotificationPage(isVendor: true),
                    )
                  : path == Routes.vendorProfile
                  ? BlocProvider(
                      create: (_) =>
                          sl<ProfileBloc>(instanceName: 'vendorProfile'),
                      child: const ProfilePage(),
                    )
                  : BlocProvider(
                      create: (_) =>
                          sl<VendorDashboardBloc>()
                            ..add(const LoadVendorDashboard()),
                      child: BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, auth) => auth is Authenticated
                            ? VendorDashboardPage(user: auth.user)
                            : const SizedBox.shrink(),
                      ),
                    ),
            ),
          ],
        ),
    ],
  ),
];

List<StatefulShellBranch> _buildEnforcerBranches() => [
  StatefulShellBranch(
    routes: [
      GoRoute(
        name: Routes.dashboardName,
        path: Routes.dashboard,
        builder: (context, state) {
          return BlocProvider(
            create: (_) => sl<DashboardBloc>()..add(LoadDashboardSummary()),
            child: const DashboardPage(),
          );
        },
      ),
    ],
  ),
  StatefulShellBranch(
    routes: [
      GoRoute(
        name: Routes.inspectionsName,
        path: Routes.inspetions,
        builder: (context, state) {
          return BlocProvider(
            create: (_) => sl<InspectionBloc>()..add(LoadInspectionTickets()),
            child: const InspectionsPage(),
          );
        },
      ),
    ],
  ),
  StatefulShellBranch(
    routes: [
      GoRoute(
        name: Routes.ticketsName,
        path: Routes.tickets,
        builder: (context, state) {
          return BlocProvider(
            create: (_) => sl<TicketBloc>()
              ..add(LoadTicketSummary(offset: 0, status: TicketStatus.pending)),
            child: const TicketsPage(),
          );
        },
      ),
    ],
  ),
  StatefulShellBranch(
    routes: [
      GoRoute(
        name: Routes.profileName,
        path: Routes.profile,
        builder: (context, state) {
          return BlocProvider(
            create: (_) => sl<ProfileBloc>(),
            child: const ProfilePage(),
          );
        },
      ),
    ],
  ),
];

CustomTransitionPage<void> _fadePage(
  BuildContext context,
  GoRouterState state, {
  required LocalKey key,
  required Widget child,
}) {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  return CustomTransitionPage<void>(
    key: key,
    name: state.name,
    child: child,
    transitionDuration: reduceMotion
        ? Duration.zero
        : AppTheme.pageTransitionDuration,
    reverseTransitionDuration: reduceMotion
        ? Duration.zero
        : AppTheme.pageReverseTransitionDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      return FadeTransition(
        opacity: animation.drive(CurveTween(curve: Curves.easeOutCubic)),
        child: child,
      );
    },
  );
}
