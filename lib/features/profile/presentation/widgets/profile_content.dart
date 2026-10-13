import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_state.dart';
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_event.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/profile_header_card.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/profile_account_card.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/profile_actions.dart';

class ProfileContent extends StatelessWidget {
  final User user;
  const ProfileContent({required this.user, super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      key: const PageStorageKey('profile'),
      padding: AppTheme.profilePagePadding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppTheme.profilePageMaxWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BlocSelector<ProfileBloc, ProfileState, bool>(
                selector: (state) => state is ProfilePhotoLoading,
                builder: (context, loading) => ProfileHeaderCard(
                  user: user,
                  isPhotoUpdating: loading,
                  onChangePhoto: (file) => context.read<ProfileBloc>().add(
                    ChangeProfilePhoto(file: file),
                  ),
                  onRemovePhoto: () =>
                      context.read<ProfileBloc>().add(RemoveProfilePhoto()),
                ),
              ),
              const SizedBox(height: AppTheme.profileSectionGap),
              Text(
                'Account information',
                style: AppTheme.profileHeadingStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.profileSmallGap),
              Text(
                'Your account details and information.',
                textAlign: TextAlign.center,
                style: AppTheme.profileBodyStyle.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppTheme.profileGap),
              ProfileAccountCard(user: user),
              const SizedBox(height: AppTheme.profileGap),
              ProfileActions(user: user),
            ],
          ),
        ),
      ),
    ),
  );
}
