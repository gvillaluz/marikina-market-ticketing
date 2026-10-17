import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';
import 'package:marikina_market_mobile/features/auth/domain/enums/role.dart';
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
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'My Profile',
                        style: AppTheme.profileHeroTitleStyle,
                      ),
                    ),
                    if (user.role == Role.marketVendor)
                      IconButton(
                        tooltip: 'My QR Code',
                        style: IconButton.styleFrom(
                          foregroundColor: AppTheme.profileHeroForeground,
                          backgroundColor: AppTheme.profileHeroOverlay,
                        ),
                        onPressed: () => context.pushNamed(Routes.vendorQrName),
                        icon: const Icon(Icons.qr_code_2),
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
                  user.role == Role.marketVendor
                      ? [
                          user.vendor?.businessName,
                          if (user.vendor?.stallNumber?.isNotEmpty == true)
                            'Stall ${user.vendor!.stallNumber}',
                        ].whereType<String>().join(' · ')
                      : user.role.value,
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
