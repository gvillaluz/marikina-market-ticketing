import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/utils/date_formatter_util.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/profile_detail_item.dart';

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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final pairMetadata =
          constraints.maxWidth - AppTheme.profileHeaderPadding.horizontal >=
              AppTheme.profileMetadataMinWidth &&
          MediaQuery.textScalerOf(
                context,
              ).scale(AppTheme.profileBodyStyle.fontSize!) <=
              AppTheme.profileBodyStyle.fontSize! *
                  AppTheme.profileHeaderMaxTextScale;
      final username = ProfileDetailItem(
        label: 'Username',
        value: user.username,
        iconData: Icons.badge_outlined,
      );
      final memberSince = ProfileDetailItem(
        label: 'Member Since',
        value: DateTimeFormatter.getDate(user.createdAt),
        iconData: Icons.calendar_today_outlined,
      );
      final colors = Theme.of(context).colorScheme;
      return Container(
        width: double.infinity,
        padding: AppTheme.profileHeaderPadding,
        decoration: AppTheme.profileCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              style: AppTheme.profileHeadingStyle,
            ),
            const SizedBox(height: AppTheme.profileCompactGap),
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: AppTheme.controlRadius,
                ),
                child: Padding(
                  padding: AppTheme.profileStatusPadding,
                  child: Text(
                    user.role.value.replaceAllMapped(
                      RegExp(r'([a-z])([A-Z])'),
                      (match) => '${match[1]} ${match[2]}',
                    ),
                    textAlign: TextAlign.center,
                    style: AppTheme.profileBodyStyle.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.profileSmallGap),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: AppTheme.controlRadius,
              ),
              child: Padding(
                padding: EdgeInsets.all(AppTheme.profileSmallGap),
                child: pairMetadata
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: username),
                          const SizedBox(width: AppTheme.profileSmallGap),
                          Expanded(child: memberSince),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          username,
                          const SizedBox(height: AppTheme.profileSmallGap),
                          memberSince,
                        ],
                      ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
