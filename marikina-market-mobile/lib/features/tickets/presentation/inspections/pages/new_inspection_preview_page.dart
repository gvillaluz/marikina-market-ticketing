import 'package:marikina_market_mobile/features/tickets/domain/entities/inspection_verification.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/verify_inspection_input.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/person_history_sheet.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_header.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_primary_btn.dart';
import 'package:marikina_market_mobile/core/utils/date_formatter_util.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/inspection_form_data.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/dialogs/duplicate_warning_conflict_dialog.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/duplicate_ticket_dialog.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/penalty_details_section.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/photo_evidence_preview_section.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/process_loading_overlay.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/submit_confirmation_bottom_sheet.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/violation_details_section.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/violator_info_section.dart';

class NewInspectionPreviewPage extends StatefulWidget {
  final InspectionFormData formData;
  const NewInspectionPreviewPage({required this.formData, super.key});

  @override
  State<StatefulWidget> createState() => _NewInspectionPreviewPageState();
}

class _NewInspectionPreviewPageState extends State<NewInspectionPreviewPage> {
  bool _isConfirmationOpen = false;
  bool _verifying = false, _submissionUncertain = false;
  InspectionVerification? _verification;
  String? _verificationMessage;
  InspectionBloc? _inspectionBloc;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _inspectionBloc = context.read<InspectionBloc>();
  }

  @override
  void dispose() {
    _inspectionBloc?.invalidateVerification();
    super.dispose();
  }

  void _verify() {
    final data = widget.formData;
    if (data.personId == null ||
        data.penaltyType == null ||
        _verifying ||
        _submissionUncertain) {
      return;
    }
    context.read<InspectionBloc>().add(
      InspectionVerificationRequested(
        VerifyInspectionInput(
          vendorId: data.vendorSummary.id,
          personId: data.personId!,
          paperViolatorName: data.paperViolatorName ?? '',
          description: data.description,
          ordinanceIds: data.ordinances.map((o) => o.id).toList(),
          penaltyType: data.penaltyType!,
          communityServiceHours: data.communityServiceHrs,
          evidenceCount: data.evidences?.length ?? 0,
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    final categories = widget.formData.ordinances
        .map((o) => o.category)
        .toList();

    context.read<InspectionBloc>().add(
      NewInspectionSubmitted(
        personId: widget.formData.personId,
        paperViolatorName: widget.formData.paperViolatorName,
        reviewedCalculation: _verification?.reviewedCalculation,
        vendorId: widget.formData.vendorSummary.id,
        enforcerId: widget.formData.enforcerId,
        marketSectionId: widget.formData.vendorSummary.marketSectionId,
        ticketType: widget.formData.ticketType,
        ordinanceIds: widget.formData.ordinances.map((o) => o.id).toList(),
        description: widget.formData.description.trim(),
        penaltyType: widget.formData.penaltyType!,
        communityServiceHours: widget.formData.communityServiceHrs,
        primaryCategory: categories,
        evidences: widget.formData.ticketType == ViolationType.ticket
            ? widget.formData.evidences
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ViolationType ticketType = widget.formData.ticketType;
    final bool isTicket = ticketType == ViolationType.ticket;

    final fineSummary =
        _verification?.calculation ?? widget.formData.fineSummary;
    final breakdownItems = fineSummary?.breakdownItems ?? [];
    final sorted = breakdownItems.map((item) => item.severity).toList()..sort();
    final highest = sorted.isEmpty ? null : sorted.last;

    final penaltyType = widget.formData.penaltyType;

    return Scaffold(
      backgroundColor: AppTheme.ticketDetailBackground,
      appBar: AppBar(
        title: const Text(
          'New Inspection',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
      body: BlocListener<InspectionBloc, InspectionState>(
        listener: (context, state) async {
          if (state is InspectionVerificationLoading) {
            setState(() {
              _verifying = true;
              _verification = null;
              _verificationMessage = null;
            });
          }
          if (state is InspectionVerified) {
            setState(() {
              _verifying = false;
              _verification = state.verification;
              _verificationMessage =
                  'Verified. Review the calculated offense positions and fine before submitting.';
            });
          }
          if (state is InspectionVerificationError) {
            setState(() {
              _verifying = false;
              _verification = null;
              _verificationMessage = state.message;
            });
          }
          if (state is SubmitNewTicketLoading) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => PopScope(
                canPop: false,
                child: ProcessLoadingOverlay(
                  message: isTicket
                      ? 'Please wait while we issue and record your violation ticket.'
                      : 'Please wait while we issue and record your warning ticket.',
                ),
              ),
            );
          }

          void disposeDialog() {
            final rootNavigator = Navigator.of(context, rootNavigator: true);
            if (rootNavigator.canPop()) {
              rootNavigator.pop();
            }
          }

          void showSnackbar(String message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: AppColors.primaryRed,
              ),
            );
          }

          if (state is SubmitNewTicketSuccess) {
            disposeDialog();
            final result = state.result;

            context.goNamed(
              Routes.ticketDetailName,
              pathParameters: {
                'ticketId': result.inspectionSummary.ticketId.toString(),
              },
              extra: result.duplicateOrdinances,
            );
          }

          if (state is DuplicationConflictInspection) {
            setState(() {
              _verification = null;
              _verificationMessage = state.message;
            });
            disposeDialog();

            if (!context.mounted) return;

            showDialog(
              context: context,
              builder: (_) => DuplicateTicketDialog(
                message: state.message,
                duplicateOrdinances: state.duplicateOrdinances,
                onEditOrdinances: () {
                  context.pop();
                },
              ),
            );
          }

          if (state is DuplicateWarningConflict) {
            disposeDialog();

            final result = await showDialog<bool>(
              context: context,
              builder: (_) =>
                  DuplicateWarningConflictDialog(message: state.message),
            );

            if (result == true && context.mounted) {
              context.pop();
            }
          }

          if (state is InspectionSubmitConnectionError) {
            setState(() {
              _verification = null;
              _submissionUncertain = true;
              _verificationMessage = state.message;
            });
            disposeDialog();
            showSnackbar(state.message);
          }

          if (state is InspectionSubmitError) {
            setState(() {
              _verification = null;
              _verificationMessage = state.message;
            });
            disposeDialog();
            showSnackbar(state.message);
          }
        },
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppTheme.ticketDetailMaxWidth,
              ),
              child: SingleChildScrollView(
                padding: AppTheme.ticketDetailPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTicket
                          ? 'Ticket Issuance Preview'
                          : 'Written Warning Preview',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: AppTheme.inspectionFormTitleFontSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isTicket
                          ? 'Review the details and photo evidence before issuing this violation ticket.'
                          : 'Please review the details below before issuing the warning.',
                      style: const TextStyle(
                        color: AppColors.mediumGrey,
                        fontSize: AppTheme.bodyFontSize,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: AppTheme.ticketSmallGap),

                    Container(
                      decoration: AppTheme.ticketPaperDecoration,
                      padding: const EdgeInsets.only(top: 20, bottom: 20),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20),
                            child: Column(
                              children: [TicketPaperHeader(isTicket: isTicket)],
                            ),
                          ),

                          const SizedBox(height: AppTheme.ticketSmallGap),
                          const Divider(height: AppTheme.ticketSmallGap),
                          const SizedBox(height: AppTheme.ticketSmallGap),

                          Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20),
                            child: ViolatorInfoSection(
                              vendor: widget.formData.vendorSummary,
                              personId: widget.formData.personId,
                              personFullName: widget.formData.personFullName,
                              paperViolatorName:
                                  widget.formData.paperViolatorName,
                              isTicket: isTicket,
                            ),
                          ),

                          const SizedBox(height: AppTheme.ticketSmallGap),
                          Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20),
                            child: const Divider(),
                          ),
                          const SizedBox(height: AppTheme.ticketSmallGap),

                          Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20),
                            child: ViolationDetailsSection(
                              penaltyType: penaltyType,
                              fine: fineSummary,
                              ordinances: widget.formData.ordinances,
                              isTicket: isTicket,
                              marketSection: widget
                                  .formData
                                  .vendorSummary
                                  .marketSectionName,
                              description: widget.formData.description,
                            ),
                          ),

                          if (fineSummary != null &&
                              penaltyType != null &&
                              isTicket) ...[
                            const SizedBox(height: AppTheme.ticketSmallGap),
                            const Padding(
                              padding: EdgeInsets.only(left: 20, right: 20),
                              child: Divider(),
                            ),
                            const SizedBox(height: AppTheme.ticketSmallGap),

                            Padding(
                              padding: const EdgeInsets.only(
                                left: 20,
                                right: 20,
                              ),
                              child: PenaltyDetailsSection(
                                severity: highest!,
                                penaltyType: penaltyType,
                                totalFineAmount: fineSummary.totalPaymentAmount,
                                communityHrs:
                                    widget.formData.communityServiceHrs,
                              ),
                            ),
                          ],

                          const SizedBox(height: AppTheme.ticketSmallGap),
                          const Divider(height: AppTheme.ticketSmallGap),
                          const SizedBox(height: AppTheme.ticketSmallGap),

                          Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 10,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Divider(),
                                      const Text('Issued By:'),
                                      const Text(
                                        'Market Officer',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text('Marikina City Public Market'),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Divider(),
                                      const Text('Issued To:'),
                                      const Text(
                                        'Market Vendor',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Date: ${DateTimeFormatter.getDate(DateTime.now())}',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (isTicket) ...[
                      const SizedBox(height: AppTheme.ticketSmallGap),

                      const Text(
                        'Photo Evidence Record',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: AppTheme.sectionHeadingFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Photos attached to this inspection record.'),

                      const SizedBox(height: 10),

                      if (widget.formData.evidences?.isEmpty ?? true) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 32,
                            horizontal: 24,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            border: Border.all(
                              color: AppColors.lightGrey.withValues(alpha: 0.5),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: .10,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.assignment_turned_in_outlined,
                                  size: 32,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No photo evidence',
                                style: TextStyle(
                                  fontSize: AppTheme.sectionHeadingFontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'No photos are attached to this record.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: AppTheme.captionFontSize,
                                  color: AppColors.mediumGrey,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        PhotoEvidencePreviewSection(
                          evidences: widget.formData.evidences!,
                        ),
                      ],
                    ],

                    const SizedBox(height: AppTheme.ticketSmallGap),

                    if (isTicket) ...[
                      if (_verificationMessage != null)
                        Text(_verificationMessage!),
                      TextButton(
                        onPressed: () async {
                          final checked = await PersonHistorySheet.show(
                            context,
                            widget.formData.personId!,
                            widget.formData.personFullName ??
                                'Confirmed person',
                          );
                          if (mounted &&
                              checked == true &&
                              _submissionUncertain) {
                            setState(() => _submissionUncertain = false);
                          }
                        },
                        child: const Text('Check person citation history'),
                      ),
                      AppPrimaryButton(
                        label: 'Verify ticket',
                        iconData: Icons.fact_check_outlined,
                        isLoading: _verifying,
                        onPressed: _submissionUncertain ? null : _verify,
                      ),
                    ],
                    AppPrimaryButton(
                      label: 'Submit ${isTicket ? 'Ticket' : 'Warning'}',
                      iconData: Icons.gavel,
                      onPressed:
                          isTicket &&
                              (_verification == null ||
                                  _verifying ||
                                  _submissionUncertain)
                          ? null
                          : () async {
                              if (_isConfirmationOpen ||
                                  context.read<InspectionBloc>().state
                                      is SubmitNewTicketLoading) {
                                return;
                              }
                              _isConfirmationOpen = true;
                              try {
                                await showModalBottomSheet(
                                  context: context,
                                  enableDrag: true,
                                  showDragHandle: true,
                                  isScrollControlled: true,
                                  builder: (_) => SubmitConfirmationBottomSheet(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _submit(context);
                                    },
                                    fineSummary: fineSummary,
                                    penaltyType: widget.formData.penaltyType,
                                    communityServiceHrs:
                                        widget.formData.penaltyType ==
                                            PenaltyType.communityService
                                        ? widget.formData.communityServiceHrs
                                        : null,
                                    severity: highest,
                                    isTicket: isTicket,
                                  ),
                                );
                              } finally {
                                _isConfirmationOpen = false;
                              }
                            },
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: const EdgeInsets.all(15),
                          backgroundColor: Color(0xFFEBEEF1),
                          foregroundColor: Color(0xFF8F8F8F),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Back'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
