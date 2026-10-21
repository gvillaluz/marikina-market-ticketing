import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/core/utils/image_picker_util.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_settlement_data.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/settlement_heading.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/settlement_image_load_error.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/settlement_load_error.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/settlement_photo_picker_prompt.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/settlement_read_only_message.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/settlement_ui_utils.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/evidence_gallery_screen.dart';

class SettlementReceiptSection extends StatefulWidget {
  final TicketSettlementData settlement;
  final VoidCallback onRetryLoad;
  final ValueChanged<File> onSubmit;

  const SettlementReceiptSection({
    required this.settlement,
    required this.onSubmit,
    required this.onRetryLoad,
    super.key,
  });

  @override
  State<SettlementReceiptSection> createState() =>
      _SettlementReceiptSectionState();
}

class _SettlementReceiptSectionState extends State<SettlementReceiptSection> {
  XFile? _receipt;
  bool _submissionSucceeded = false;

  Future<void> _attachReceipt() async {
    final photo = await _selectPhoto();
    if (!mounted || photo == null) return;

    if (await File(photo.path).length() > 5 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt photo must be 5 MB or smaller.')),
      );
      return;
    }
    setState(() => _receipt = photo);
  }

  Future<XFile?> _selectPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
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
    if (source == null || !mounted) return null;

    return ImagePickerUtil.pickImage(
      context: context,
      source: source,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );
  }

  @override
  void didUpdateWidget(covariant SettlementReceiptSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.settlement.receiptProof != oldWidget.settlement.receiptProof &&
        widget.settlement.receiptProof?.proofUrls.isNotEmpty == true) {
      _receipt = null;
    }
    if (oldWidget.settlement.isSubmitting &&
        !widget.settlement.isSubmitting &&
        widget.settlement.receiptProof != oldWidget.settlement.receiptProof) {
      _submissionSucceeded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settlement = widget.settlement;
    final savedUrls = settlement.receiptProof?.proofUrls ?? const <String>[];
    final List<ImageProvider> evidenceProviders = savedUrls
        .map((url) => CachedNetworkImageProvider(url))
        .toList();
    if (savedUrls.isEmpty && _receipt != null) {
      evidenceProviders.add(FileImage(File(_receipt!.path)));
    }
    final isSaved =
        settlement.isReceiptSubmitted ||
        savedUrls.isNotEmpty ||
        _submissionSucceeded;
    final isPaid = settlement.ticketStatus == TicketStatus.paid;
    final canEdit = !isPaid && !isSaved && settlement.isLoaded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettlementHeading(
          title: 'Settlement Receipt',
          description:
              'Upload a photo of the official payment receipt to complete this ticket’s settlement record.',
        ),
        const SizedBox(height: 10),
        buildSettlementCard(
          child: Column(
            children: [
              if (settlement.isLoading)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: CircularProgressIndicator(),
                )
              else if (!settlement.isLoaded)
                SettlementLoadError(onRetry: widget.onRetryLoad)
              else if (isSaved)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (savedUrls.isEmpty && _receipt != null)
                      _buildReceiptImage(
                        evidenceProviders: evidenceProviders,
                        index: 0,
                        child: Image.file(
                          File(_receipt!.path),
                          cacheWidth: AppTheme.evidenceDecodeMaxWidth,
                          width: double.infinity,
                          height: 190,
                          fit: BoxFit.cover,
                        ),
                      ),
                    for (var index = 0; index < savedUrls.length; index++)
                      _buildReceiptImage(
                        evidenceProviders: evidenceProviders,
                        index: index,
                        child: CachedNetworkImage(
                          memCacheWidth: AppTheme.evidenceDecodeMaxWidth,
                          imageUrl: savedUrls[index],
                          width: double.infinity,
                          height: 190,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) =>
                              const SettlementImageLoadError(),
                        ),
                      ),
                    const SettlementReadOnlyMessage(
                      text:
                          'Settlement receipt saved. This record cannot be changed.',
                    ),
                  ],
                )
              else if (isPaid)
                const SettlementReadOnlyMessage(
                  text:
                      'This ticket is paid. Settlement details are read-only.',
                )
              else ...[
                InkWell(
                  onTap: canEdit ? _attachReceipt : null,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 135),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.lightGrey.withValues(alpha: .7),
                      ),
                    ),
                    child: _receipt == null
                        ? const SettlementPhotoPickerPrompt(
                            label: 'Tap to attach receipt photo',
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: Image.file(
                              File(_receipt!.path),
                              cacheWidth: AppTheme.evidenceDecodeMaxWidth,
                              fit: BoxFit.cover,
                              height: 190,
                              width: double.infinity,
                            ),
                          ),
                  ),
                ),
                if (_receipt != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: !canEdit || settlement.isSubmitting
                          ? null
                          : () => widget.onSubmit(File(_receipt!.path)),
                      icon: settlement.isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.upload_outlined, size: 18),
                      label: Text(
                        settlement.isSubmitting
                            ? 'Saving receipt...'
                            : 'Save Receipt',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptImage({
    required List<ImageProvider> evidenceProviders,
    required int index,
    required Widget child,
  }) {
    final imageProvider = evidenceProviders[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => EvidenceGalleryScreen(
              imageProviders: evidenceProviders,
              initialIndex: index,
              isEditing: false,
            ),
          ),
        ),
        child: Hero(
          tag: imageProvider,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: child,
          ),
        ),
      ),
    );
  }
}
