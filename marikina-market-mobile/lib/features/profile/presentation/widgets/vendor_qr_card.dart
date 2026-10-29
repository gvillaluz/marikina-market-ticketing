import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/profile_portrait.dart';

class VendorQrCard extends StatelessWidget {
  final User user;
  const VendorQrCard({required this.user, super.key});
  @override
  Widget build(BuildContext context) {
    final vendor = user.vendor!;
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: AppTheme.profileCardPadding,
      decoration: AppTheme.profileCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ProfilePortrait(
              profileUrl: user.profileUrl,
              size: AppTheme.profileQrAvatarSize,
            ),
          ),
          const SizedBox(height: AppTheme.profileSmallGap),
          Text(
            '${user.firstName} ${user.lastName}',
            textAlign: TextAlign.center,
            style: AppTheme.sectionHeadingStyle.copyWith(color: colors.primary),
          ),
          const SizedBox(height: AppTheme.profileCompactGap),
          Text(
            [
              vendor.businessName,
              if (vendor.stallNumber?.isNotEmpty == true)
                'Stall ${vendor.stallNumber}',
            ].join(' · '),
            textAlign: TextAlign.center,
            style: AppTheme.captionTextStyle.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTheme.profileSmallGap),
          const Divider(),
          LayoutBuilder(
            builder: (context, constraints) => Center(
              child: QrImageView(
                data: vendor.qrCodeValue,
                size: math.min(AppTheme.profileQrSize, constraints.maxWidth),
                padding: AppTheme.profileQrPadding,
                backgroundColor: AppTheme.profileHeroForeground,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppTheme.profileHeroColor,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppTheme.profileHeroColor,
                ),
                semanticsLabel: 'Vendor registration QR code',
              ),
            ),
          ),
          const SizedBox(height: AppTheme.profileSmallGap),
          Text(
            'Business Account Number',
            textAlign: TextAlign.center,
            style: AppTheme.captionTextStyle.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTheme.profileCompactGap),
          Text(
            vendor.businessAccountNumber,
            textAlign: TextAlign.center,
            style: AppTheme.cardHeadingStyle.copyWith(color: colors.primary),
          ),
        ],
      ),
    );
  }
}
