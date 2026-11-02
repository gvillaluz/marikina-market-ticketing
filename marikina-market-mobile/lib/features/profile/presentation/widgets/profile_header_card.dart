import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/profile_avatar.dart';

class ProfileHeaderCard extends StatelessWidget {
  final User user;
  final ValueChanged<XFile> onChangePhoto;
  final VoidCallback onRemovePhoto;
  final bool isPhotoUpdating;
  const ProfileHeaderCard({
    required this.user,
    required this.onChangePhoto,
    required this.onRemovePhoto,
    this.isPhotoUpdating = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) => ClipRect(
    child: ColoredBox(
      color: AppTheme.profileHeroColor,
      child: Stack(
        children: [
          Positioned(
            right: -AppTheme.profileHeroCircleSize / 3,
            top: -AppTheme.profileHeroCircleSize / 2,
            child: Container(
              width: AppTheme.profileHeroCircleSize,
              height: AppTheme.profileHeroCircleSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.profileHeroOverlay,
              ),
            ),
          ),
          Positioned(
            left: -AppTheme.profileHeroCircleSize / 2,
            bottom: -AppTheme.profileHeroCircleSize / 2,
            child: Container(
              width: AppTheme.profileHeroCircleSize,
              height: AppTheme.profileHeroCircleSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.profileHeroOverlay,
              ),
            ),
          ),
          Padding(
            padding: AppTheme.profilePagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'My Profile',
                        style: AppTheme.profileHeroTitleStyle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.profileSmallGap),
                Center(
                  child: ProfileAvatar(
                    profileUrl: user.profileUrl,
                    onChangePhoto: onChangePhoto,
                    onRemovePhoto: onRemovePhoto,
                    isUpdating: isPhotoUpdating,
                  ),
                ),
                const SizedBox(height: AppTheme.profileSmallGap),
                Text(
                  '${user.lastName}, ${user.firstName}',
                  textAlign: TextAlign.center,
                  style: AppTheme.sectionHeadingStyle.copyWith(
                    color: AppTheme.profileHeroForeground,
                  ),
                ),
                const SizedBox(height: AppTheme.profileCompactGap),
                Text(
                  user.role.value,
                  textAlign: TextAlign.center,
                  style: AppTheme.pageSubtitleStyle.copyWith(
                    color: AppTheme.profileHeroForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
