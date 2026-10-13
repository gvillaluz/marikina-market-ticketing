import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/widgets/dashboard_actions.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/widgets/user_banner.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/widgets/weekly_overview_section.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous is! Authenticated && current is Authenticated,
      listener: (context, state) =>
          context.read<DashboardBloc>().add(LoadDashboardSummary()),
      child: RefreshIndicator(
        onRefresh: () => context.read<DashboardBloc>().refresh(),
        child: SingleChildScrollView(
          key: const PageStorageKey('dashboard'),
          padding: AppTheme.dashboardPagePadding,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppTheme.dashboardMaxWidth,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashboardHeader(),
                  SizedBox(height: AppTheme.dashboardGap),
                  UserBanner(),
                  SizedBox(height: AppTheme.dashboardGap),
                  DashboardActions(),
                  SizedBox(height: AppTheme.dashboardSectionGap),
                  WeeklyOverviewSection(),
                  SizedBox(height: AppTheme.dashboardGap),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
