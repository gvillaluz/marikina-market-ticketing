import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marikina_market_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_state.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/edit_appbar.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/edit_profile_card.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/edit_profile_heading.dart';

class EditProfilePage extends StatelessWidget {
  final User user;
  const EditProfilePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) => BlocConsumer<ProfileBloc, ProfileState>(
    listener: (context, state) {
      if (state is ProfileUpdated) {
        context.read<AuthBloc>().add(UserUpdated(state.user));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account information updated successfully!'),
          ),
        );
        context.pop();
      }
    },
    builder: (context, state) => PopScope(
      canPop: state is! EditProfileLoading,
      child: Scaffold(
        appBar: EditAppbar(
          title: 'Edit Account Information',
          onPressed: state is EditProfileLoading ? null : () => context.pop(),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: AppTheme.profilePagePadding,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppTheme.profileFormMaxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const EditProfileHeading(),
                    EditProfileCard(user: user),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
