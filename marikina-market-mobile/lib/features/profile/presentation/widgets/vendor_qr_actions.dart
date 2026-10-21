import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class VendorQrActions extends StatelessWidget {
  final bool busy;
  final bool sharing;
  final VoidCallback onShare;
  final VoidCallback onSave;
  const VendorQrActions({
    required this.busy,
    required this.sharing,
    required this.onShare,
    required this.onSave,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _button(
        context,
        'Share QR Code',
        'Sharing…',
        Icons.ios_share,
        onShare,
        loading: busy && sharing,
      ),
      const SizedBox(height: AppTheme.profileActionGap),
      _button(
        context,
        'Download QR Code',
        'Preparing download…',
        Icons.download_outlined,
        onSave,
        loading: busy && !sharing,
      ),
    ],
  );
  Widget _button(
    BuildContext context,
    String label,
    String loadingLabel,
    IconData icon,
    VoidCallback action, {
    required bool loading,
  }) => OutlinedButton.icon(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppTheme.profileHeroForeground,
      disabledForegroundColor: loading
          ? AppTheme.profileHeroForeground
          : AppTheme.profileHeroForeground.withValues(alpha: .5),
      disabledBackgroundColor: AppTheme.profileHeroOverlay,
      backgroundColor: AppTheme.profileHeroOverlay,
      side: const BorderSide(color: AppTheme.profileHeroOverlay),
      padding: AppTheme.profileQrActionPadding,
      textStyle: Theme.of(context).textTheme.labelLarge,
    ),
    onPressed: busy ? null : action,
    icon: loading
        ? SizedBox.square(
            dimension: AppTheme.buttonIconSize,
            child: CircularProgressIndicator(
              strokeWidth: AppTheme.buttonProgressStrokeWidth,
              color: AppTheme.profileHeroForeground,
              value: MediaQuery.disableAnimationsOf(context) ? 0.75 : null,
              semanticsLabel: loadingLabel,
            ),
          )
        : Icon(icon),
    label: Semantics(
      liveRegion: loading,
      child: Text(loading ? loadingLabel : label, textAlign: TextAlign.center),
    ),
  );
}
