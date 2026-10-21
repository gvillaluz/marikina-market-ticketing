import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';
import '../bloc/vendor_dashboard_bloc.dart';
import '../bloc/vendor_dashboard_state.dart';
import '../widgets/vendor_dashboard_header.dart';
import '../widgets/vendor_dashboard_content.dart';
import '../widgets/vendor_dashboard_skeleton.dart';
import '../widgets/vendor_dashboard_notice.dart';

class VendorDashboardPage extends StatelessWidget {
  final User user;
  const VendorDashboardPage({required this.user, super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ColoredBox(
      color: AppTheme.recordsBackground,
      child: RefreshIndicator(
        onRefresh: context.read<VendorDashboardBloc>().refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VendorDashboardHeader(user: user),
              ColoredBox(
                color: AppTheme.profileHeroColor,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.recordsBackground,
                    borderRadius: AppTheme.vendorDashboardSectionRadius,
                  ),
                  padding: AppTheme.vendorDashboardPadding.subtract(
                    const EdgeInsets.only(top: AppTheme.dashboardSmallGap),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppTheme.dashboardMaxWidth,
                      ),
                      child: BlocBuilder<VendorDashboardBloc, VendorDashboardState>(
                        builder: (context, state) {
                          final refresh = context
                              .read<VendorDashboardBloc>()
                              .refresh;
                          if (state.summary == null) {
                            if (state.error == null) {
                              return const VendorDashboardSkeleton();
                            }
                            return VendorDashboardNotice(
                              title: "We couldn't load your dashboard",
                              message: state.error!,
                              icon: Icons.cloud_off_outlined,
                              onRetry: refresh,
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (state.error != null) ...[
                                VendorDashboardNotice(
                                  title: "Couldn't refresh your dashboard",
                                  message:
                                      '${state.error!}\nYour last loaded information is shown below.',
                                  icon: Icons.sync_problem_outlined,
                                  onRetry: refresh,
                                  compact: true,
                                ),
                                const SizedBox(
                                  height: AppTheme.dashboardSmallGap,
                                ),
                              ],
                              VendorDashboardContent(
                                summary: state.summary!,
                                onRefresh: refresh,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
