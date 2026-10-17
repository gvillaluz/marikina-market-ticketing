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
import 'package:marikina_market_mobile/features/profile/presentation/widgets/logout_confirmation_dialog.dart';

class ProfileActions extends StatelessWidget {
  final User user;
  const ProfileActions({required this.user, super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const LogoutConfirmationDialog(),
    );
    if (confirmed == true && context.mounted) {
      context.read<AuthBloc>().add(LogoutUser(false));
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AppPrimaryButton(
        label: 'Edit Information',
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
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      const SizedBox(height: AppTheme.profileActionGap),
      AppOutlinedBtn(
        label: 'Log Out',
        iconData: Icons.logout,
        onPressed: () => _confirmLogout(context),
        foregroundColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
    ],
  );
}
