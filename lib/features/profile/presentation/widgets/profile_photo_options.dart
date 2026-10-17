import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/profile/domain/enums/avatar_action.dart';

class ProfilePhotoOptions extends StatelessWidget {
  final bool hasPhoto;
  const ProfilePhotoOptions({required this.hasPhoto, super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: AppTheme.profilePhotoMenuPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Profile photo', style: AppTheme.detailTitleStyle),
          const SizedBox(height: AppTheme.profileSmallGap),
          Text(
            'Choose how you want to update your photo.',
            style: AppTheme.bodyTextStyle.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTheme.profileSmallGap),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.photo_library_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(hasPhoto ? 'Change Photo' : 'Add Photo'),
            subtitle: const Text('Choose from your gallery'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pop(context, AvatarAction.changePhoto),
          ),
          if (hasPhoto)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Remove Photo',
                style: AppTheme.bodyTextStyle.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              subtitle: const Text('Use the default avatar'),
              onTap: () => Navigator.pop(context, AvatarAction.removePhoto),
            ),
          const SizedBox(height: AppTheme.profileSmallGap),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ),
  );
}
