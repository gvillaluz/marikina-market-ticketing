import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_outlined_btn.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_primary_btn.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_event.dart';

class ProfileActions extends StatelessWidget {
  final User user;
  const ProfileActions({required this.user, super.key});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      AppPrimaryButton(
        label: 'Edit Account Information',
        iconData: Icons.edit_square,
        onPressed: () => context.pushNamed(Routes.editProfileName, extra: user),
      ),
      const SizedBox(height: AppTheme.profileActionGap),
      AppOutlinedBtn(
        label: 'Change Password',
        iconData: Icons.lock_outline,
        onPressed: () =>
            context.pushNamed(Routes.changePasswordName, extra: user),
        foregroundColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      const SizedBox(height: AppTheme.profileGap),
      const Divider(),
      const SizedBox(height: AppTheme.profileActionGap),
      AppOutlinedBtn(
        label: 'Logout',
        iconData: Icons.logout,
        onPressed: () => context.read<AuthBloc>().add(LogoutUser(false)),
        foregroundColor: Theme.of(context).colorScheme.error,
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
      ),
    ],
  );
}
