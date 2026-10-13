import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_primary_btn.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/dashboard/presentation/widgets/view_inspections_btn.dart';

class DashboardActions extends StatelessWidget {
  const DashboardActions({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AppPrimaryButton(
        label: 'New Inspection',
        iconData: Icons.add,
        onPressed: () => context.pushNamed(Routes.newInspectionName),
      ),
      const SizedBox(height: AppTheme.dashboardSmallGap),
      const ViewInspectionsBtn(),
    ],
  );
}
