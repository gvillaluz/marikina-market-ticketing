import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';
import 'package:marikina_market_mobile/features/profile/domain/use_cases/export_qr_params.dart';
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_event.dart';
import 'package:marikina_market_mobile/features/profile/presentation/bloc/profile_state.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/vendor_qr_card.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/vendor_qr_actions.dart';

class VendorQrContent extends StatefulWidget {
  final User user;
  const VendorQrContent({required this.user, super.key});
  @override
  State<VendorQrContent> createState() => _VendorQrContentState();
}

class _VendorQrContentState extends State<VendorQrContent> {
  final _cardKey = GlobalKey();
  bool _capturing = false;
  bool _sharing = false;
  Future<void> _export(bool share) async {
    if (_capturing ||
        context.read<ProfileBloc>().state is ProfileQrExportLoading) {
      return;
    }
    setState(() {
      _capturing = true;
      _sharing = share;
    });
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('QR card is unavailable.');
      final image = await boundary.toImage(
        pixelRatio: AppTheme.profileQrExportScale,
      );
      final ByteData? bytes;
      try {
        bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      } finally {
        image.dispose();
      }
      if (!mounted || bytes == null) return;
      final origin = boundary.localToGlobal(Offset.zero);
      context.read<ProfileBloc>().add(
        ExportVendorQr(
          ExportQrParams(
            pngBytes: bytes.buffer.asUint8List(),
            businessAccountNumber: widget.user.vendor!.businessAccountNumber,
            share: share,
            origin: (
              x: origin.dx,
              y: origin.dy,
              width: boundary.size.width,
              height: boundary.size.height,
            ),
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to prepare your QR code. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: AppTheme.profilePagePadding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppTheme.profileQrMaxWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Show this QR code to the market inspector to verify your business registration.',
                textAlign: TextAlign.center,
                style: AppTheme.bodyTextStyle.copyWith(
                  color: AppTheme.profileHeroForeground,
                ),
              ),
              const SizedBox(height: AppTheme.profileSectionGap),
              RepaintBoundary(
                key: _cardKey,
                child: VendorQrCard(user: widget.user),
              ),
              const SizedBox(height: AppTheme.profileGap),
              BlocBuilder<ProfileBloc, ProfileState>(
                builder: (context, state) => VendorQrActions(
                  busy: _capturing || state is ProfileQrExportLoading,
                  sharing: _sharing,
                  onShare: () => _export(true),
                  onSave: () => _export(false),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
