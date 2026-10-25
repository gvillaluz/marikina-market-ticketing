import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/utils/image_picker_util.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_primary_btn.dart';
import '../bloc/vendor_settlement/vendor_settlement_bloc.dart';
import '../bloc/vendor_settlement/vendor_settlement_state.dart';
import '../bloc/vendor_settlement/submit_vendor_receipt.dart';
import '../bloc/vendor_settlement/clear_vendor_receipt_upload_error.dart';
import 'vendor_settlement_photo.dart';

class VendorReceiptSection extends StatefulWidget {
  final VendorSettlementState settlement;
  const VendorReceiptSection({required this.settlement, super.key});
  @override
  State<VendorReceiptSection> createState() => _VendorReceiptSectionState();
}

class _VendorReceiptSectionState extends State<VendorReceiptSection> {
  XFile? _photo;
  bool _selecting = false;
  String? _pickerError;
  @override
  void didUpdateWidget(covariant VendorReceiptSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.settlement.hasUploaded ||
        widget.settlement.receipt?.proofUrls.isNotEmpty == true) {
      _photo = null;
    }
  }

  Future<void> _pick() async {
    if (_selecting || !widget.settlement.canUpload) return;
    setState(() {
      _selecting = true;
      _pickerError = null;
    });
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        showDragHandle: true,
        useSafeArea: true,
        sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
            ? AnimationStyle.noAnimation
            : null,
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from photos'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (!mounted || source == null || !widget.settlement.canUpload) return;
      final photo = await ImagePickerUtil.pickImage(
        context: context,
        source: source,
        imageQuality: 85,
      );
      if (mounted && photo != null && widget.settlement.canUpload) {
        setState(() => _photo = photo);
        context.read<VendorSettlementBloc>().add(
          const ClearVendorReceiptUploadError(),
        );
      }
    } on PlatformException {
      if (mounted) {
        setState(
          () => _pickerError = 'Unable to select a photo. Please try again.',
        );
      }
    } on MissingPluginException {
      if (mounted) {
        setState(
          () => _pickerError = 'Photo selection is unavailable on this device.',
        );
      }
    } finally {
      if (mounted) setState(() => _selecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.settlement;
    final urls = state.receipt?.proofUrls ?? const <String>[];
    final saved = state.hasUploaded || urls.isNotEmpty;
    final paid = state.detail?.status == TicketStatus.paid;
    final busy = _selecting || state.isUploading;
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final url in urls)
          VendorSettlementPhoto(url: url, title: 'Settlement receipt'),
        if (saved)
          Text(
            'Settlement receipt saved. This record cannot be changed.',
            style: AppTheme.inspectionBodyStyle,
          )
        else if (paid)
          Text(
            'This ticket is paid. Settlement details are read-only.',
            style: AppTheme.inspectionBodyStyle,
          )
        else ...[
          Material(
            color: colors.surfaceContainerLow,
            borderRadius: AppTheme.controlRadius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: state.canUpload && !busy ? _pick : null,
              child: Padding(
                padding: AppTheme.settlementCardPadding,
                child: _photo == null
                    ? Column(
                        children: [
                          const Icon(Icons.add_photo_alternate_outlined),
                          const SizedBox(height: AppTheme.profileSmallGap),
                          Text(
                            _selecting
                                ? 'Opening photos…'
                                : 'Attach receipt photo',
                            textAlign: TextAlign.center,
                            style: AppTheme.inspectionHeadingStyle,
                          ),
                          const Text(
                            'JPG, JPEG, or PNG • Maximum 5 MB',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    : Image.file(
                        File(_photo!.path),
                        height: AppTheme.settlementImageHeight,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        cacheWidth: AppTheme.evidenceDecodeMaxWidth,
                        errorBuilder: (context, error, stack) => const Text(
                          'Photo unavailable. Choose another photo.',
                        ),
                      ),
              ),
            ),
          ),
          if (_photo != null)
            TextButton.icon(
              onPressed: busy
                  ? null
                  : () {
                      setState(() => _photo = null);
                      context.read<VendorSettlementBloc>().add(
                        const ClearVendorReceiptUploadError(),
                      );
                    },
              icon: const Icon(Icons.close),
              label: const Text('Remove photo'),
            ),
          const SizedBox(height: AppTheme.profileSmallGap),
          AppPrimaryButton(
            label: 'Submit receipt',
            iconData: Icons.upload_file,
            isLoading: state.isUploading,
            onPressed: !state.canUpload || busy || _photo == null
                ? null
                : () => context.read<VendorSettlementBloc>().add(
                    SubmitVendorReceipt(_photo!.path),
                  ),
          ),
        ],
        if (_pickerError != null)
          Text(
            _pickerError!,
            style: AppTheme.inspectionBodyStyle.copyWith(color: colors.error),
          ),
        if (state.uploadError != null) ...[
          const SizedBox(height: AppTheme.profileSmallGap),
          Text(
            state.uploadError!,
            style: AppTheme.inspectionBodyStyle.copyWith(color: colors.error),
          ),
        ],
      ],
    );
  }
}
