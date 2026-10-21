import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/connectivity/connectivity_status.dart';
import 'package:marikina_market_mobile/core/connectivity/cubit/connectivity_cubit.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';
import 'package:marikina_market_mobile/features/auth/domain/enums/role.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';

class UserBanner extends StatelessWidget {
  const UserBanner({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<AuthBloc, AuthState, User?>(
        selector: (state) => state is Authenticated ? state.user : null,
        builder: (context, user) {
          final colors = Theme.of(context).colorScheme;
          if (user == null) {
            return Container(
              width: double.infinity,
              padding: AppTheme.dashboardCardPadding,
              decoration: BoxDecoration(
                color: colors.errorContainer,
                borderRadius: AppTheme.dashboardCardRadius,
              ),
              child: Text(
                'Sign in to view your market activity.',
                style: AppTheme.dashboardBodyStyle.copyWith(
                  color: colors.onErrorContainer,
                ),
              ),
            );
          }
          final role = switch (user.role) {
            Role.marketEnforcer => 'Market Enforcer',
            Role.marketVendor => 'Market Vendor',
            Role.adminOfficer => 'Admin Officer',
            Role.headAdmin => 'Head Admin',
          };
          return Container(
            width: double.infinity,
            padding: AppTheme.dashboardCardPadding,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: AppTheme.dashboardCardRadius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${user.firstName} ${user.lastName}',
                  style: AppTheme.dashboardHeadingStyle.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: AppTheme.dashboardTinyGap),
                Text(
                  role,
                  style: AppTheme.dashboardBodyStyle.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: AppTheme.dashboardSmallGap),
                BlocSelector<ConnectivityCubit, ConnectivityStatus, bool>(
                  selector: (status) => status == ConnectivityStatus.online,
                  builder: (context, isOnline) => Row(
                    children: [
                      Container(
                        height: AppTheme.dashboardStatusDotSize,
                        width: AppTheme.dashboardStatusDotSize,
                        decoration: BoxDecoration(
                          color: isOnline
                              ? AppTheme.dashboardOnlineColor
                              : colors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppTheme.dashboardTinyGap),
                      Flexible(
                        child: Text(
                          isOnline ? 'Online' : 'Offline',
                          style: AppTheme.dashboardBodyStyle.copyWith(
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
}
