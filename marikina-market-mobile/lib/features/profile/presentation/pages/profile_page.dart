import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_state.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/profile_content.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/profile_page_skeleton.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/profile_unavailable.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => BlocListener<ProfileBloc, ProfileState>(
    listener: (context, state) {
      if (state is ProfilePictureChanged) {
        context.read<AuthBloc>().add(UserUpdated(state.user));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated successfully.')),
        );
      }
      if (state is ChangeProfilePhotoFailed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              state.message.trim().isEmpty
                  ? 'Unable to update your profile photo. Please try again.'
                  : state.message,
            ),
          ),
        );
      }
    },
    child: BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) =>
          previous is! Authenticated ||
          current is! Authenticated ||
          !identical(previous.user, current.user),
      builder: (context, state) {
        if (state is AuthLoading || state is AuthInitial) {
          return const ProfilePageSkeleton();
        }
        if (state is Authenticated) return ProfileContent(user: state.user);
        return ProfileUnavailable(
          message: state is AuthError
              ? state.message
              : 'Please sign in again to view your profile.',
        );
      },
    ),
  );
}
