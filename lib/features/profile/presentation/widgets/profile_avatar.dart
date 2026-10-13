import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/utils/image_picker_util.dart';
import 'package:marikina_market_mobile/features/profile/domain/enums/avatar_action.dart';

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

  @override
  Widget build(BuildContext context) {
    final busy = _selecting || widget.isUpdating;
    final url = widget.profileUrl;
    final pixels =
        (AppTheme.profileAvatarSize * MediaQuery.devicePixelRatioOf(context))
            .ceil()
            .clamp(1, AppTheme.profileAvatarDecodeMaxWidth)
            .toInt();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipOval(
          child: Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            width: AppTheme.profileAvatarSize,
            height: AppTheme.profileAvatarSize,
            child: url == null || url.trim().isEmpty
                ? Icon(
                    Icons.person_outline,
                    size: AppTheme.profileAvatarSize / 2,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : CachedNetworkImage(
                    key: ValueKey(url),
                    imageUrl: url,
                    memCacheWidth: pixels,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Icon(
                      Icons.person_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.person_outline,
                      semanticLabel: 'Profile photo unavailable',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: PopupMenuButton<AvatarAction>(
            tooltip: busy ? 'Updating profile photo' : 'Profile photo actions',
            enabled: !busy,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: AvatarAction.changePhoto,
                child: Text(
                  url == null || url.trim().isEmpty
                      ? 'Add Photo'
                      : 'Change Photo',
                ),
              ),
              if (url != null && url.trim().isNotEmpty)
                const PopupMenuItem(
                  value: AvatarAction.removePhoto,
                  child: Text('Remove Photo'),
                ),
            ],
            onSelected: (action) {
              if (action == AvatarAction.changePhoto) {
                _choosePhoto();
              } else {
                widget.onRemovePhoto();
              }
            },
            child: Material(
              type: MaterialType.transparency,
              child: SizedBox.square(
                dimension: AppTheme.buttonMinSize.width,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Ink(
                    decoration: ShapeDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: CircleBorder(
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.surface,
                        ),
                      ),
                    ),
                    child: SizedBox.square(
                      dimension: AppTheme.profilePhotoButtonSize,
                      child: Center(
                        child: busy
                            ? SizedBox.square(
                                dimension: AppTheme.profilePhotoIconSize,
                                child: CircularProgressIndicator(
                                  value: MediaQuery.disableAnimationsOf(context)
                                      ? 0.75
                                      : null,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  strokeWidth:
                                      AppTheme.buttonProgressStrokeWidth,
                                  semanticsLabel: 'Updating profile photo',
                                  semanticsValue: 'In progress',
                                ),
                              )
                            : Icon(
                                Icons.camera_alt_outlined,
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: AppTheme.profilePhotoIconSize,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
