// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/di/dependency_injection.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_primary_btn.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/duplicate_ordinance.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/inspection_form_data.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ordinance.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/vendor_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/warning_ordinance.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/add_photo_evidence_btn.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/dialogs/duplicate_warning_dialog.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/inspection_type_toggle.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/payment_type_section.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/bottom_sheets/select_ordinance_bottom_sheet.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/ticket_violation_card.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/vendor_summary_banner.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/violator_info_card.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class AddNewInspectionPage extends StatefulWidget {
  final User user;

  const AddNewInspectionPage({required this.user, super.key});

  @override
  State<StatefulWidget> createState() => _AddNewInspectionPageState();
}

class _AddNewInspectionPageState extends State<AddNewInspectionPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _ticketDescriptionController =
      TextEditingController();
  final TextEditingController _communityHrsController = TextEditingController();

  String? _photoError;
  String? _ordinanceError;
  String? _communityHrsError;
  String? _descriptionError;
  String? _vendorError;

  ViolationType _selectedType = ViolationType.warning;

  VendorSummary? _vendorSummary;
  FineSummary? _fineSummary;

  List<Ordinance> _selectedOrdinances = [];
  final List<XFile> _capturedEvidences = [];
  bool _hasTextDraft = false;
  bool _isOpeningPreview = false;

  PenaltyType _selectedPenaltyType = PenaltyType.cashFine;

  @override
  void initState() {
    super.initState();
    _ticketDescriptionController.addListener(_updateTextDraft);
    _communityHrsController.addListener(_updateTextDraft);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      WakelockPlus.enable();
      context.read<InspectionBloc>().add(LoadOrdinances());
    });
  }

  @override
  void dispose() {
    _ticketDescriptionController.dispose();
    _communityHrsController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void _onChangeOrdinance(List<Ordinance> ordinances) {
    setState(() {
      _selectedOrdinances = ordinances;
      if (ordinances.isNotEmpty) _ordinanceError = null;
    });
  }

  void _onDeleteFineSummary(int index) {
    final isTicket = _selectedType == ViolationType.ticket;
    if (_selectedOrdinances.isEmpty || index >= _selectedOrdinances.length)
      return;

    setState(() {
      final removedOrdinance = _selectedOrdinances[index];
      _selectedOrdinances.removeAt(index);

      if (isTicket && _fineSummary != null) {
        _fineSummary!.breakdownItems.removeWhere(
          (item) => item.ordinanceId == removedOrdinance.id,
        );
        if (_highestSelectedSeverity == Severity.high) {
          _selectedPenaltyType = PenaltyType.cashFine;
        }
      }
    });
  }

  Severity get _highestSelectedSeverity {
    final breakdownItems = _fineSummary?.breakdownItems ?? [];
    if (breakdownItems.isEmpty) return Severity.minor;

    return breakdownItems
        .map((item) => item.severity)
        .reduce(
          (highest, severity) =>
              severity.compareTo(highest) > 0 ? severity : highest,
        );
  }

  bool get _isFormEmpty {
    final isTicket = _selectedType == ViolationType.ticket;
    final hasVendorOrOrdinances =
        _vendorSummary != null || _selectedOrdinances.isNotEmpty;
    final hasEvidences = isTicket && _capturedEvidences.isNotEmpty;
    return !hasVendorOrOrdinances && !hasEvidences && !_hasTextDraft;
  }

  void _updateTextDraft() {
    final hasText =
        _ticketDescriptionController.text.trim().isNotEmpty ||
        _communityHrsController.text.trim().isNotEmpty;
    if (hasText != _hasTextDraft) setState(() => _hasTextDraft = hasText);
  }

  Future<bool> _confirmDiscard(BuildContext context) async {
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        actionsAlignment: MainAxisAlignment.center,
        titlePadding: const EdgeInsets.only(bottom: 0),
        contentPadding: const EdgeInsets.only(
          top: 7,
          left: 20,
          right: 20,
          bottom: 10,
        ),

        icon: Icon(Icons.info_outline, size: 50, color: AppColors.primaryRed),
        title: const Text('Discard Inspection?', textAlign: TextAlign.center),
        content: const Text(
          'Your changes will be lost if you leave this page.',
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Stay'),
                ),
              ),
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryRed,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Discard'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return confirmed == true;
  }

  Future<void> _handleOrdinanceSelect(BuildContext context) async {
    if (_vendorSummary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.primary,
          content: Text(
            'Please fill out vendor\'s information first.',
            style: TextStyle(color: AppColors.primaryLight),
          ),
        ),
      );
      return;
    }

    final selectionResult = await showModalBottomSheet<Object>(
      context: context,
      enableDrag: true,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : const AnimationStyle(
              duration: AppTheme.pageTransitionDuration,
              reverseDuration: AppTheme.pageReverseTransitionDuration,
            ),
      builder: (context) => BlocProvider(
        create: (_) => sl<InspectionBloc>(),
        child: SelectOrdinanceBottomSheet(
          isWarningTicket: _selectedType == ViolationType.warning
              ? true
              : false,
          ordinances: _selectedOrdinances,
          onChanged: _onChangeOrdinance,
          vendorId: _vendorSummary?.id,
        ),
      ),
    );

    if (!mounted) return;
    if (selectionResult is List<WarningOrdinance>) {
      _showOrdinanceConflictBanner(
        title: 'Existing warning ordinances',
        message:
            'The vendor has already received a warning for these ordinances. They were removed from this inspection.',
        ordinances: selectionResult
            .map(
              (ordinance) => DuplicateOrdinance(
                ordinanceId: ordinance.ordinanceId,
                ordinanceNo: ordinance.ordinanceNo,
                ordinanceCode: ordinance.ordinanceCode,
              ),
            )
            .toList(),
      );
      return;
    }

    if (selectionResult is FineSummary) {
      bool hasDuplicate = false;
      List<DuplicateOrdinance> duplicateOrdinances = [];

      setState(() {
        _fineSummary = selectionResult;
        if (_highestSelectedSeverity == Severity.high) {
          _selectedPenaltyType = PenaltyType.cashFine;
        }

        final duplicatedSummaryIds = _fineSummary?.breakdownItems
            .where((f) => f.isDuplicate == true)
            .map((f) => f.ordinanceId)
            .toSet();

        if (duplicatedSummaryIds != null && duplicatedSummaryIds.isNotEmpty) {
          hasDuplicate = true;

          duplicateOrdinances = _fineSummary!.breakdownItems
              .where((f) => f.isDuplicate)
              .map(
                (item) => DuplicateOrdinance(
                  ordinanceId: item.ordinanceId,
                  ordinanceNo: item.ordinanceNo,
                  ordinanceCode: item.ordinanceCode,
                ),
              )
              .toList();

          _selectedOrdinances.removeWhere(
            (o) => duplicatedSummaryIds.contains(o.id),
          );
          _fineSummary!.breakdownItems.removeWhere((o) => o.isDuplicate);
        }
      });

      if (hasDuplicate) {
        _showOrdinanceConflictBanner(
          title: 'Existing ticket ordinances',
          message:
              'The vendor already has an open ticket for these ordinances. They were removed from this inspection.',
          ordinances: duplicateOrdinances,
        );
      }
    }
  }

  void _showOrdinanceConflictBanner({
    required String title,
    required String message,
    required List<DuplicateOrdinance> ordinances,
  }) {
    if (ordinances.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner();
    final ordinanceCount = ordinances.length;
    final ordinanceLabel = ordinanceCount == 1 ? 'ordinance' : 'ordinances';
    messenger.showMaterialBanner(
      MaterialBanner(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        forceActionsBelow: false,
        backgroundColor: AppColors.tertiaryYellow,
        leading: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.secondaryYellow,
          size: 22,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.secondaryYellow,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$ordinanceCount $ordinanceLabel excluded from this inspection.',
              style: const TextStyle(
                color: AppColors.secondaryYellow,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => showAdaptiveDialog(
              context: context,
              builder: (_) => DuplicateWarningDialog(
                title: title,
                description: message,
                duplicateOrdinances: ordinances,
              ),
            ),
            child: const Text(
              'VIEW',
              style: TextStyle(
                color: AppColors.secondaryYellow,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Dismiss',
            visualDensity: VisualDensity.compact,
            onPressed: messenger.hideCurrentMaterialBanner,
            icon: const Icon(
              Icons.close,
              color: AppColors.secondaryYellow,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  void addEvidence(XFile photo) => setState(() {
    _capturedEvidences.add(photo);
    _photoError = null;
  });

  void removeEvidence(int index) =>
      setState(() => _capturedEvidences.removeAt(index));

  void _populateVendorInfo(VendorSummary vendor) {
    setState(() {
      _vendorError = null;
      _vendorSummary = vendor;
    });
  }

  void _onChangePenaltyType(PenaltyType value) {
    setState(() => _selectedPenaltyType = value);
  }

  bool _validateForm() {
    final isTicket = _selectedType == ViolationType.ticket;

    final isTextValid = _formKey.currentState?.validate() ?? false;

    setState(() {
      _vendorError = _vendorSummary == null
          ? 'Please select a registered vendor or enter stall info.'
          : null;

      _ordinanceError = _selectedOrdinances.isEmpty
          ? 'Please select at least one ordinance.'
          : null;

      _descriptionError = _ticketDescriptionController.text.trim().isEmpty
          ? 'Description is required.'
          : null;

      _photoError = (isTicket && _capturedEvidences.isEmpty)
          ? 'At least one photo evidence is required for tickets.'
          : null;

      if (isTicket && _selectedPenaltyType == PenaltyType.communityService) {
        final hours = int.tryParse(_communityHrsController.text.trim());
        _communityHrsError = (hours == null || hours < 3)
            ? 'Minimum of 3 hours required.'
            : null;
      } else {
        _communityHrsError = null;
      }
    });

    return isTextValid &&
        _vendorError == null &&
        _ordinanceError == null &&
        _descriptionError == null &&
        _photoError == null &&
        _communityHrsError == null;
  }

  Future<void> _submit() async {
    if (_isOpeningPreview || !_validateForm()) return;

    final isTicket = _selectedType == ViolationType.ticket;
    int? communityHrs;
    if (isTicket && _selectedPenaltyType == PenaltyType.communityService) {
      communityHrs = int.tryParse(_communityHrsController.text.trim());
    }

    setState(() => _isOpeningPreview = true);
    try {
      await context.pushNamed<void>(
        Routes.newInspectionPreviewName,
        extra: InspectionFormData(
          enforcerId: widget.user.userId,
          vendorSummary: _vendorSummary!,
          fineSummary: _fineSummary,
          ordinances: _selectedOrdinances,
          evidences: _capturedEvidences,
          description: _ticketDescriptionController.text.trim(),
          ticketType: _selectedType,
          penaltyType: _selectedPenaltyType,
          communityServiceHrs: communityHrs,
        ),
      );
    } finally {
      if (mounted) setState(() => _isOpeningPreview = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isTicket = _selectedType == ViolationType.ticket;

    return PopScope(
      canPop: _isFormEmpty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmDiscard(context) && context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'New Inspection',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Inspection details',
                        style: TextStyle(
                          color: AppColors.primaryBlack,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _vendorSummary == null
                            ? 'Select a registered vendor or enter the stall information to begin.'
                            : 'Complete the inspection details, then review them before submitting.',
                        style: const TextStyle(
                          color: AppColors.mediumGrey,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_vendorSummary == null) ...[
                        ViolatorInfoCard(
                          onVendorSelected: _populateVendorInfo,
                          errorMessage: _vendorError,
                        ),
                        const SizedBox(height: 20),
                      ],

                      if (_vendorSummary != null) ...[
                        VendorSummaryBanner(
                          vendor: _vendorSummary!,
                          onChangeVendor: () =>
                              setState(() => _vendorSummary = null),
                        ),

                        const SizedBox(height: 20),

                        InspectionTypeToggle(
                          selected: _selectedType,
                          onChange: (type) => setState(() {
                            _selectedType = type;
                            _selectedOrdinances = [];
                            _fineSummary = null;
                            _photoError = null;
                            _ordinanceError = null;
                            _communityHrsError = null;
                          }),
                          isEnabled: true,
                        ),

                        const SizedBox(height: 20),

                        TicketViolationCard(
                          onPressed: _handleOrdinanceSelect,
                          onDelete: _onDeleteFineSummary,
                          ordinances: _selectedOrdinances,
                          capturedPhotos: _capturedEvidences,
                          fineSummary: _fineSummary,
                          isTicket: isTicket,
                          errorMessage: _ordinanceError,
                        ),

                        if (_fineSummary != null &&
                            _fineSummary!.breakdownItems.isNotEmpty &&
                            isTicket &&
                            _selectedOrdinances.isNotEmpty) ...[
                          PaymentTypeSection(
                            selectedPenaltyType: _selectedPenaltyType,
                            severity: _highestSelectedSeverity,
                            totalFineAmount:
                                _fineSummary?.totalPaymentAmount ?? 0.0,
                            onChangeType: _onChangePenaltyType,
                            communityHrsController: _communityHrsController,
                            communityHrsError: _communityHrsError,
                          ),
                          const SizedBox(height: 20),
                        ],

                        const Text('DESCRIPTION'),
                        const SizedBox(height: 5),
                        TextFormField(
                          controller: _ticketDescriptionController,
                          maxLines: 5,
                          minLines: 3,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          onTapOutside: (event) =>
                              FocusScope.of(context).unfocus(),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Description is required.';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            errorText: _descriptionError,
                            border: const OutlineInputBorder(),
                          ),
                        ),

                        if (isTicket) ...[
                          const SizedBox(height: 20),
                          const Text('PHOTO EVIDENCE'),
                          const SizedBox(height: 5),

                          AddPhotoEvidenceBtn(
                            photos: _capturedEvidences,
                            onPhotoAdded: (photo) => addEvidence(photo),
                            onPhotoRemoved: (index) => removeEvidence(index),
                            isInvalid: _photoError != null,
                          ),

                          if (_photoError != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Text(
                                    _photoError!,
                                    style: const TextStyle(
                                      color: AppColors.primaryRed,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],

                        const SizedBox(height: 30),

                        AppPrimaryButton(
                          label: 'Submit ${isTicket ? 'Ticket' : 'Warning'}',
                          iconData: Icons.gavel,
                          isLoading: _isOpeningPreview,
                          onPressed: _submit,
                        ),

                        const SizedBox(height: 10),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryRed,
                              backgroundColor: AppColors.secondaryRed
                                  .withValues(alpha: .30),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              side: BorderSide(color: AppColors.primaryRed),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            onPressed: () async {
                              if (_isFormEmpty) {
                                Navigator.of(context).pop();
                              } else if (await _confirmDiscard(context) &&
                                  context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
