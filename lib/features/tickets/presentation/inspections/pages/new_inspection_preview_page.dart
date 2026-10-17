import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:dotted_line/dotted_line.dart';
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
  void _submit(BuildContext context) {
    final categories = widget.formData.ordinances
        .map((o) => o.category)
        .toList();

    context.read<InspectionBloc>().add(
      NewInspectionSubmitted(
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

    final breakdownItems = widget.formData.fineSummary?.breakdownItems ?? [];
    final sorted = breakdownItems.map((item) => item.severity).toList()..sort();
    final highest = sorted.isEmpty ? null : sorted.last;

    final fineSummary = widget.formData.fineSummary;
    final penaltyType = widget.formData.penaltyType;

    return Scaffold(
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
            disposeDialog();
            showSnackbar(state.message);
            if (context.mounted) {
              context.pop();
            }
          }

          if (state is InspectionSubmitError) {
            disposeDialog();
            showSnackbar(state.message);
            if (context.mounted) {
              context.pop();
            }
          }
        },
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
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

                    const SizedBox(height: 20),

                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: AppColors.primaryLight,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .25),
                            offset: const Offset(-1, 1),
                            blurRadius: 3.5,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.only(top: 20, bottom: 20),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20),
                            child: Column(
                              children: [
                                const Text(
                                  'City of Marikina',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: AppTheme.sectionHeadingFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text('Marikina Public Market Office'),

                                const SizedBox(height: 20),

                                Row(
                                  spacing: 5,
                                  children: [
                                    Image.asset(
                                      'assets/logo/org_logo.png',
                                      height: 50,
                                      width: 50,
                                    ),
                                    Text(
                                      isTicket
                                          ? 'VIOLATION TICKET'
                                          : 'WRITTEN WARNING',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize:
                                            AppTheme.sectionHeadingFontSize,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const Spacer(),

                                    if (isTicket) ...[
                                      const Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'CONTROL NO.',
                                            style: TextStyle(
                                              color: AppColors.mediumGrey,
                                              fontSize:
                                                  AppTheme.captionFontSize,
                                            ),
                                          ),
                                          Text(
                                            'PENDING',
                                            style: TextStyle(
                                              color: AppColors.primaryRed,
                                              fontWeight: FontWeight.bold,
                                              fontSize: AppTheme
                                                  .sectionHeadingFontSize,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),
                          const DottedLine(
                            dashLength: 5,
                            dashColor: AppColors.lightGrey,
                          ),
                          const SizedBox(height: 20),

                          Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20),
                            child: ViolatorInfoSection(
                              vendor: widget.formData.vendorSummary,
                              isTicket: isTicket,
                            ),
                          ),

                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20),
                            child: const Divider(),
                          ),
                          const SizedBox(height: 20),

                          Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20),
                            child: ViolationDetailsSection(
                              fine: widget.formData.fineSummary,
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
                            const SizedBox(height: 20),
                            const Padding(
                              padding: EdgeInsets.only(left: 20, right: 20),
                              child: Divider(),
                            ),
                            const SizedBox(height: 20),

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

                          const SizedBox(height: 20),
                          const DottedLine(
                            dashLength: 5,
                            dashColor: AppColors.lightGrey,
                          ),
                          const SizedBox(height: 20),

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
                      const SizedBox(height: 20),

                      const Text(
                        'Photo Evidence Record',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: AppTheme.sectionHeadingFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'The image below serves as the photo evidence attached to this violation ticket.',
                      ),

                      const SizedBox(height: 10),

                      if (widget.formData.evidences == null) ...[
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
                                'No Photo Evidences Found',
                                style: TextStyle(
                                  fontSize: AppTheme.sectionHeadingFontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'There are no captured or recorded photo evidences for this ticket.',
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

                    const SizedBox(height: 20),

                    AppPrimaryButton(
                      label: 'Submit ${isTicket ? 'Ticket' : 'Warning'}',
                      iconData: Icons.gavel,
                      onPressed: () async {
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
                              fineSummary: widget.formData.fineSummary,
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
