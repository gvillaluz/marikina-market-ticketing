import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_outlined_btn.dart';

class ViewInspectionsBtn extends StatelessWidget {
  const ViewInspectionsBtn({super.key});

  @override
  Widget build(BuildContext context) => AppOutlinedBtn(
    label: 'View My Inspections',
    iconData: Icons.search,
    onPressed: () => context.go(Routes.inspetions),
    foregroundColor: Theme.of(context).colorScheme.primary,
    backgroundColor: Theme.of(context).colorScheme.surface,
  );
}
