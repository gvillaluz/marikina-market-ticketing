import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/utils/password_change_check.dart';
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_state.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/profile_password_field.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/save_btn.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/back_btn.dart';

class ChangePasswordCard extends StatelessWidget {
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmNewPasswordController;
  final PasswordChangeCheck? check;
  final VoidCallback submit;
  const ChangePasswordCard({
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmNewPasswordController,
    this.check,
    required this.submit,
    super.key,
  });
  @override
  Widget build(BuildContext context) => BlocBuilder<ProfileBloc, ProfileState>(
    builder: (context, state) {
      final loading = state is ChangePasswordLoading;
      final String? message = switch (state) {
        ChangePasswordError(:final message) ||
        ChangePasswordNetworkError(:final message) => message,
        _ => null,
      };
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfilePasswordField(
            label: 'Current Password',
            hint: 'Enter password',
            controller: currentPasswordController,
            enabled: !loading,
            isNewPassword: false,
            errorText: check?.currentError,
          ),
          const SizedBox(height: AppTheme.profileGap),
          ProfilePasswordField(
            label: 'New Password',
            hint: 'Enter new password',
            controller: newPasswordController,
            enabled: !loading,
            errorText: check?.newPasswordError,
          ),
          const SizedBox(height: AppTheme.profileSmallGap),
          Text(
            PasswordChangeCheck.hint,
            style: AppTheme.profileBodyStyle.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTheme.profileGap),
          ProfilePasswordField(
            label: 'Confirm New Password',
            hint: 'Confirm new password',
            controller: confirmNewPasswordController,
            enabled: !loading,
            errorText: check?.confirmError,
            onSubmitted: submit,
          ),
          const SizedBox(height: AppTheme.profileGap),
          Text(
            'Choose a strong password that is different from your current password. Keep it private.',
            style: AppTheme.profileBodyStyle.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppTheme.profileSmallGap),
            Semantics(
              liveRegion: true,
              child: Text(
                message.trim().isEmpty
                    ? 'Unable to change your password. Please try again.'
                    : message,
                style: AppTheme.profileBodyStyle.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppTheme.profileGap),
          SaveBtn(onPressed: submit, isLoading: loading, label: 'Save Changes'),
          const SizedBox(height: AppTheme.profileActionGap),
          BackBtn(enabled: !loading, label: 'Cancel'),
        ],
      );
    },
  );
}
