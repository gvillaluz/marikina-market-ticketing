import 'package:marikina_market_mobile/features/profile/presentation/widgets/profile_portrait.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/utils/image_picker_util.dart';
import 'package:marikina_market_mobile/features/profile/domain/enums/avatar_action.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/profile_photo_options.dart';

class ProfileAvatar extends StatefulWidget {
  final String? profileUrl;
  final ValueChanged<XFile> onChangePhoto;
  final VoidCallback onRemovePhoto;
  final bool isUpdating;
  const ProfileAvatar({
    this.profileUrl,
    required this.onChangePhoto,
    required this.onRemovePhoto,
    this.isUpdating = false,
    super.key,
  });
  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  bool _selecting = false;
  Future<void> _choosePhoto() async {
    if (_selecting || widget.isUpdating) return;
    setState(() => _selecting = true);
    try {
      final photo = await ImagePickerUtil.pickImage(
        context: context,
        source: ImageSource.gallery,
      );
      if (mounted && photo != null) widget.onChangePhoto(photo);
    } on PlatformException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open your photos. Please try again.'),
          ),
        );
      }
    } on MissingPluginException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo selection is unavailable on this device.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _selecting = false);
    }
  }

  Future<void> _openPhotoOptions() async {
    if (_selecting || widget.isUpdating) return;
    final action = await showModalBottomSheet<AvatarAction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ProfilePhotoOptions(
        hasPhoto: widget.profileUrl?.trim().isNotEmpty == true,
      ),
    );
    if (!mounted || widget.isUpdating) return;
    if (action == AvatarAction.changePhoto) {
      await _choosePhoto();
    } else if (action == AvatarAction.removePhoto) {
      widget.onRemovePhoto();
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _selecting || widget.isUpdating;
    final colors = Theme.of(context).colorScheme;
    // Reserve both the visible outset and the padded button's hit area.
    final photoInset =
        AppTheme.profileSmallGap +
        (AppTheme.buttonMinSize.width - AppTheme.profilePhotoButtonSize) / 2;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.all(photoInset),
          child: ProfilePortrait(profileUrl: widget.profileUrl),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: IconButton.filled(
            tooltip: busy ? 'Updating profile photo' : 'Profile photo actions',
            onPressed: busy ? null : _openPhotoOptions,
            style: IconButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              disabledBackgroundColor: colors.primary,
              disabledForegroundColor: colors.onPrimary,
              minimumSize: const Size.square(AppTheme.profilePhotoButtonSize),
              maximumSize: const Size.square(AppTheme.profilePhotoButtonSize),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.padded,
              side: BorderSide(
                color: colors.surface,
                width: AppTheme.profilePhotoBorderWidth,
              ),
            ),
            icon: busy
                ? SizedBox.square(
                    dimension: AppTheme.profilePhotoIconSize,
                    child: CircularProgressIndicator(
                      value: MediaQuery.disableAnimationsOf(context)
                          ? 0.75
                          : null,
                      color: colors.onPrimary,
                      strokeWidth: AppTheme.buttonProgressStrokeWidth,
                      semanticsLabel: 'Updating profile photo',
                    ),
                  )
                : const Icon(
                    Icons.camera_alt_outlined,
                    size: AppTheme.profilePhotoIconSize,
                  ),
          ),
        ),
      ],
    );
  }
}
