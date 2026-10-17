import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';
import 'package:marikina_market_mobile/features/auth/domain/enums/role.dart';
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_state.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/profile_unavailable.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/vendor_qr_content.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/vendor_qr_background.dart';

class VendorQrPage extends StatelessWidget {
  final User user;
  const VendorQrPage({required this.user, super.key});
  @override
  Widget build(BuildContext context) => VendorQrBackground(
    child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        foregroundColor: AppTheme.profileHeroForeground,
        iconTheme: const IconThemeData(color: AppTheme.profileHeroForeground),
        centerTitle: true,
        leading: Padding(
          padding: AppTheme.profileQrBackButtonPadding,
          child: BackButton(
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.profileHeroOverlay,
              shape: const RoundedRectangleBorder(
                borderRadius: AppTheme.profileQrBackButtonRadius,
              ),
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.goNamed(Routes.vendorProfileName);
              }
            },
          ),
        ),
        title: Text(
          'My QR Code',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            color: AppTheme.profileHeroForeground,
          ),
        ),
      ),
      body:
          user.role != Role.marketVendor ||
              user.vendor?.qrCodeValue.trim().isNotEmpty != true
          ? ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: const ProfileUnavailable(
                message:
                    'Your saved QR code is unavailable. Please sign in again to update your profile.',
              ),
            )
          : BlocListener<ProfileBloc, ProfileState>(
              listener: (context, state) {
                final message = switch (state) {
                  ProfileQrExportFinished(:final message) => message,
                  ProfileQrExportError(:final message) => message,
                  _ => null,
                };
                if (message != null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(message)));
                }
              },
              child: VendorQrContent(user: user),
            ),
    ),
  );
}
