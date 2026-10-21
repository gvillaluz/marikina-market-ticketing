import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';
import 'package:marikina_market_mobile/core/utils/image_picker_util.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/community_service_log.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/submit_community_service_log_params.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_settlement_data.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/settlement_heading.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/settlement_image_load_error.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/settlement_load_error.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/settlement_photo_picker_prompt.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/settlement_read_only_message.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/settlement_ui_utils.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/evidence_gallery_screen.dart';

class CommunityServiceLogSection extends StatefulWidget {
  final TicketSettlementData settlement;
  final VoidCallback onRetryLoad;
  final ValueChanged<SubmitCommunityServiceLogParams> onSubmit;

  const CommunityServiceLogSection({
    required this.settlement,
    required this.onSubmit,
    required this.onRetryLoad,
    super.key,
  });

  @override
  State<CommunityServiceLogSection> createState() =>
      _CommunityServiceLogSectionState();
}

class _CommunityServiceLogSectionState
    extends State<CommunityServiceLogSection> {
  final _hoursController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  XFile? _proofPhoto;
  bool _isAddingLog = false;
  int? _expandedLogIndex;

  @override
  void dispose() {
    _hoursController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CommunityServiceLogSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.settlement.communityServiceProgress !=
            oldWidget.settlement.communityServiceProgress &&
        oldWidget.settlement.isSubmitting &&
        !widget.settlement.isSubmitting) {
      _resetForm();
      _expandedLogIndex = widget.settlement.communityServiceProgress == null
          ? null
          : widget.settlement.communityServiceProgress!.entries.length - 1;
    }
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (selectedDate != null && mounted) {
      setState(() => _selectedDate = selectedDate);
    }
  }

  Future<void> _attachProof() async {
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
    if (source == null || !mounted) return;

    final photo = await ImagePickerUtil.pickImage(
      context: context,
      source: source,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (!mounted || photo == null) return;

    if (await File(photo.path).length() > 5 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proof photo must be 5 MB or smaller.')),
      );
      return;
    }
    setState(() => _proofPhoto = photo);
  }

  void _submitLog() {
    if (widget.settlement.isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    final proofPhoto = _proofPhoto;
    if (proofPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attach proof documentation to continue.'),
        ),
      );
      return;
    }
    final hours = double.parse(_hoursController.text.trim());
    widget.onSubmit(
      SubmitCommunityServiceLogParams(
        ticketId: widget.settlement.ticketId,
        proofFile: File(proofPhoto.path),
        serviceDate: _selectedDate,
        hoursWorked: hours,
      ),
    );
  }

  void _resetForm() {
    _hoursController.clear();
    _proofPhoto = null;
    _selectedDate = DateTime.now();
    _isAddingLog = false;
  }

  @override
  Widget build(BuildContext context) {
    final settlement = widget.settlement;
    final progress = settlement.communityServiceProgress;
    final requiredHours = progress?.hoursRequired ?? settlement.requiredHours;
    final completedHours = progress?.hoursCompleted ?? 0;
    final hasRequirement = requiredHours != null && requiredHours > 0;
    final isComplete =
        progress != null && progress.hoursCompleted >= progress.hoursRequired;
    final isPaid = settlement.ticketStatus == TicketStatus.paid;
    final canEdit = !isPaid && !isComplete && settlement.isLoaded;
    final percentage = progress == null
        ? 0.0
        : (progress.completionPercentage / 100).clamp(0.0, 1.0);
    final evidenceProviders =
        progress?.entries
            .map((entry) => CachedNetworkImageProvider(entry.proofUrl))
            .toList() ??
        const <ImageProvider>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettlementHeading(
          title: 'Community Service Log',
          description:
              'Track hours rendered for community service against the required hours on this ticket.',
        ),
        const SizedBox(height: 10),
        buildSettlementCard(
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColors.tertiaryYellow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.access_time,
                      color: AppColors.secondaryYellow,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Community Service Log',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: AppTheme.bodyFontSize,
                          ),
                        ),
                        Text(
                          hasRequirement
                              ? '${formatSettlementHours(completedHours)} of $requiredHours hrs completed'
                              : 'Community service progress is unavailable',
                          style: const TextStyle(
                            color: AppColors.mediumGrey,
                            fontSize: AppTheme.captionFontSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (settlement.isLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                )
              else if (!settlement.isLoaded)
                SettlementLoadError(onRetry: widget.onRetryLoad)
              else if (progress == null)
                const Text(
                  'Unable to load community service entries.',
                  style: TextStyle(color: AppColors.mediumGrey),
                )
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${formatSettlementHours(progress.hoursCompleted)} logged',
                      style: const TextStyle(
                        color: AppColors.mediumGrey,
                        fontSize: AppTheme.captionFontSize,
                      ),
                    ),
                    Text(
                      '${progress.completionPercentage.round()}% of ${progress.hoursRequired} hrs',
                      style: const TextStyle(
                        color: AppColors.mediumGrey,
                        fontSize: AppTheme.captionFontSize,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: percentage,
                    minHeight: 7,
                    backgroundColor: AppColors.tertiary,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 5),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${formatSettlementHours(progress.hoursRemaining)} hrs remaining',
                    style: const TextStyle(
                      color: AppColors.mediumGrey,
                      fontSize: AppTheme.captionFontSize,
                    ),
                  ),
                ),
                if (progress.entries.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  for (var index = 0; index < progress.entries.length; index++)
                    _buildLogEntry(
                      progress.entries[index],
                      index,
                      evidenceProviders,
                    ),
                ],
              ],
              if (isPaid)
                const SettlementReadOnlyMessage(
                  text:
                      'This ticket is paid. Settlement details are read-only.',
                )
              else if (isComplete)
                const SettlementReadOnlyMessage(
                  text: 'Required community service hours are complete.',
                )
              else if (canEdit && progress != null) ...[
                const SizedBox(height: 10),
                if (_isAddingLog)
                  _buildLogForm()
                else
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _isAddingLog = true),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Service Entry'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.tertiary),
                      minimumSize: const Size(double.infinity, 38),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogEntry(
    CommunityServiceLog log,
    int index,
    List<ImageProvider> evidenceProviders,
  ) {
    final isExpanded = _expandedLogIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.tertiary),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () =>
                setState(() => _expandedLogIndex = isExpanded ? null : index),
            borderRadius: BorderRadius.circular(9),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('MMM d, yyyy').format(log.serviceDate),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: AppTheme.captionFontSize,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.blueBackgroundColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${formatSettlementHours(log.hoursWorked)}h',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: AppTheme.captionFontSize,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: AppColors.mediumGrey,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow(
                    'Date',
                    DateFormat('MM/dd/yyyy').format(log.serviceDate),
                  ),
                  const SizedBox(height: 6),
                  _detailRow(
                    'Hours worked',
                    '${formatSettlementHours(log.hoursWorked)} hours',
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
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
                      tag: evidenceProviders[index],
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          memCacheWidth: AppTheme.evidenceDecodeMaxWidth,
                          imageUrl: log.proofUrl,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) =>
                              const SettlementImageLoadError(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.mediumGrey,
              fontSize: AppTheme.captionFontSize,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: AppTheme.captionFontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogForm() {
    return AbsorbPointer(
      absorbing: widget.settlement.isSubmitting,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.tertiary),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Date',
                style: TextStyle(fontSize: AppTheme.captionFontSize),
              ),
              const SizedBox(height: 5),
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today_outlined, size: 17),
                  ),
                  child: Text(DateFormat('MM/dd/yyyy').format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Hours Worked',
                style: TextStyle(fontSize: AppTheme.captionFontSize),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: _hoursController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  hintText: 'Enter hours',
                ),
                validator: (value) {
                  final hours = double.tryParse(value?.trim() ?? '');
                  if (hours == null ||
                      !hours.isFinite ||
                      hours < 0.01 ||
                      hours > 999.99) {
                    return 'Enter 0.01 to 999.99 hours.';
                  }
                  if (!RegExp(r'^\d*(\.\d{0,2})?$').hasMatch(value!.trim())) {
                    return 'Use at most 2 decimal places.';
                  }
                  final remaining = widget
                      .settlement
                      .communityServiceProgress
                      ?.hoursRemaining;
                  if (remaining != null && hours > remaining) {
                    return 'Hours cannot exceed the remaining ${formatSettlementHours(remaining)} hours.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 9),
              const Text(
                'Proof Documentation',
                style: TextStyle(fontSize: AppTheme.captionFontSize),
              ),
              const SizedBox(height: 5),
              InkWell(
                onTap: _attachProof,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  height: 92,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.lightGrey),
                  ),
                  child: _proofPhoto == null
                      ? const SettlementPhotoPickerPrompt(
                          label: 'Tap to attach proof photo',
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.file(
                            File(_proofPhoto!.path),
                            cacheWidth: AppTheme.evidenceDecodeMaxWidth,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  TextButton(
                    onPressed: () => setState(_resetForm),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: widget.settlement.isSubmitting
                          ? null
                          : _submitLog,
                      icon: widget.settlement.isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add, size: 16),
                      label: Text(
                        widget.settlement.isSubmitting
                            ? 'Saving...'
                            : 'Log Hours',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(0, 40),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
