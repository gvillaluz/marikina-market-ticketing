import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class ProfilePortrait extends StatelessWidget {
  final String? profileUrl;
  final double size;
  const ProfilePortrait({
    required this.profileUrl,
    this.size = AppTheme.profileAvatarSize,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    final url = profileUrl;
    final pixels = (size * MediaQuery.devicePixelRatioOf(context))
        .ceil()
        .clamp(1, AppTheme.profileAvatarDecodeMaxWidth)
        .toInt();
    final fallback = Icon(
      Icons.person_outline,
      size: size / 2,
      color: Theme.of(context).colorScheme.primary,
    );
    return ClipOval(
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: SizedBox.square(
          dimension: size,
          child: url == null || url.trim().isEmpty
              ? fallback
              : CachedNetworkImage(
                  key: ValueKey(url),
                  imageUrl: url,
                  memCacheWidth: pixels,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => fallback,
                  errorWidget: (_, _, _) => Semantics(
                    label: 'Profile photo unavailable',
                    child: fallback,
                  ),
                ),
        ),
      ),
    );
  }
}
