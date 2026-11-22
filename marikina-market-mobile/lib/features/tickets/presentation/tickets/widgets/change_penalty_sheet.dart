import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_outlined_btn.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_primary_btn.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/skeleton_box.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/change_penalty_params.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/penalty_options.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/penalty_change_reason.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/payment_type_section.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/bloc/ticket_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/bloc/ticket_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/bloc/ticket_state.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/penalty_change_reason_options.dart';

class ChangePenaltySheet extends StatefulWidget {
  final int ticketId;

  const ChangePenaltySheet({required this.ticketId, super.key});

  static Future<void> show(BuildContext context, int ticketId) async {
    final bloc = context.read<TicketBloc>()..add(LoadPenaltyOptions(ticketId));
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      // A drag or handle tap closes the sheet past PopScope, even during a save.
      enableDrag: false,
      showDragHandle: false,
      sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : const AnimationStyle(
              duration: AppTheme.pageTransitionDuration,
              reverseDuration: AppTheme.pageReverseTransitionDuration,
            ),
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: ChangePenaltySheet(ticketId: ticketId),
      ),
    );

    // A failed save may be out of date, or saved before the connection dropped.
    final state = bloc.state;
    if (!bloc.isClosed &&
        state is TicketDetailLoaded &&
        state.penaltyChangeError != null) {
      bloc.add(LoadTicketDetail(ticketId));
    }
  }

  @override
  State<ChangePenaltySheet> createState() => _ChangePenaltySheetState();
}

class _ChangePenaltySheetState extends State<ChangePenaltySheet> {
  static const _minimumHours = 3;

  final _hoursController = TextEditingController(text: '$_minimumHours');
  PenaltyType? _selectedType;
  PenaltyChangeReason? _reason;

  @override
  void initState() {
    super.initState();
    // The choices can arrive before the sheet's first build.
    _prefillHours(context.read<TicketBloc>().state);
    _hoursController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _hoursController.dispose();
    super.dispose();
  }

  void _prefillHours(TicketState state) {
    if (state is! TicketDetailLoaded) return;
    final hours = state.penaltyOptions?.communityServiceHours;
    if (hours != null) _hoursController.text = '$hours';
  }

  void _onStateChanged(BuildContext context, TicketState state) {
    if (state is TicketDetailLoaded) return _prefillHours(state);
    // The ticket reloads after a save. Only pop this sheet, never the page under it.
    if (ModalRoute.of(context)?.isCurrent ?? false) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TicketBloc, TicketState>(
      listenWhen: (previous, current) =>
          current is! TicketDetailLoaded ||
          (previous is TicketDetailLoaded &&
              previous.penaltyOptions != current.penaltyOptions),
      listener: _onStateChanged,
      // Keep the last content while the sheet animates away.
      buildWhen: (_, current) => current is TicketDetailLoaded,
      builder: (context, state) {
        if (state is! TicketDetailLoaded) return const SizedBox.shrink();

        return PopScope(
          canPop: !state.isChangingPenalty,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: AppTheme.selectionSheetPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Change penalty',
                        style: AppTheme.detailTitleStyle.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.ticketGap),
                    if (state.penaltyOptions case final options?)
                      ..._buildForm(state, options)
                    else if (state.penaltyOptionsError case final error?)
                      ..._buildLoadError(error)
                    else
                      for (final _ in PenaltyType.values)
                        const SkeletonBox(height: kMinInteractiveDimension),
                    const SizedBox(height: AppTheme.ticketSmallGap),
                    AppOutlinedBtn(
                      label: 'Cancel',
                      iconData: Icons.close,
                      onPressed: state.isChangingPenalty
                          ? null
                          : () => Navigator.pop(context),
                      foregroundColor: AppColors.primary,
                      backgroundColor: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildLoadError(String error) => [
    _errorText(error),
    const SizedBox(height: AppTheme.ticketGap),
    AppPrimaryButton(
      label: 'Retry',
      iconData: Icons.refresh,
      onPressed: () =>
          context.read<TicketBloc>().add(LoadPenaltyOptions(widget.ticketId)),
    ),
  ];

  List<Widget> _buildForm(TicketDetailLoaded state, PenaltyOptions options) {
    final allowed = options.allowedPenaltyTypes;
    final current = options.currentPenaltyType;
    final selected = _selectedType ?? current ?? PenaltyType.cashFine;
    final isDifferent = selected != current && allowed.contains(selected);

    final hours = selected == PenaltyType.communityService
        ? int.tryParse(_hoursController.text.trim())
        : null;
    final hoursError =
        isDifferent &&
            selected == PenaltyType.communityService &&
            (hours == null || hours < _minimumHours)
        ? 'Enter at least $_minimumHours hours.'
        : null;

    final reason = _reason;
    final missing = !isDifferent
        ? 'Select a different penalty.'
        : reason == null
        ? 'Select a reason for the change.'
        : null;

    return [
      AbsorbPointer(
        absorbing: state.isChangingPenalty,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PaymentTypeSection(
              selectedPenaltyType: selected,
              allowCashFine: allowed.contains(PenaltyType.cashFine),
              // The current penalty stays selectable, or the section would show Cash fine as selected.
              allowBloodDonation:
                  allowed.contains(PenaltyType.bloodDonation) ||
                  current == PenaltyType.bloodDonation,
              allowCommunityService:
                  allowed.contains(PenaltyType.communityService) ||
                  current == PenaltyType.communityService,
              totalFineAmount: options.cashFineAmount,
              onChangeType: (type) => setState(() => _selectedType = type),
              communityHrsController: _hoursController,
              communityHrsError: hoursError,
            ),
            if (PenaltyType.values.any(
              (type) => type != current && !allowed.contains(type),
            )) ...[
              const SizedBox(height: AppTheme.ticketTinyGap),
              _noteText(
                "Greyed choices aren't allowed for this ticket under the market code.",
              ),
            ],
            const SizedBox(height: AppTheme.ticketGap),
            PenaltyChangeReasonOptions(
              selected: reason,
              onChanged: (value) => setState(() => _reason = value),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppTheme.ticketGap),
      if (state.penaltyChangeError case final error?) ...[
        _errorText(error),
        _noteText('Closing this panel reloads the ticket.'),
        const SizedBox(height: AppTheme.ticketSmallGap),
      ] else if (missing != null) ...[
        Semantics(liveRegion: true, child: _noteText(missing)),
        const SizedBox(height: AppTheme.ticketSmallGap),
      ],
      AppPrimaryButton(
        label: 'Save change',
        iconData: Icons.check,
        isLoading: state.isChangingPenalty,
        onPressed: !isDifferent || hoursError != null || reason == null
            ? null
            : () => _save(options, selected, hours, reason),
      ),
    ];
  }

  void _save(
    PenaltyOptions options,
    PenaltyType type,
    int? hours,
    PenaltyChangeReason reason,
  ) {
    FocusScope.of(context).unfocus();
    context.read<TicketBloc>().add(
      ChangePenalty(
        ChangePenaltyParams(
          ticketId: widget.ticketId,
          penaltyType: type,
          communityServiceHours: hours,
          reason: reason,
          version: options.version,
        ),
      ),
    );
  }

  Widget _noteText(String text) => Text(
    text,
    style: AppTheme.captionTextStyle.copyWith(color: AppColors.paperLabelGrey),
  );

  Widget _errorText(String text) => Semantics(
    liveRegion: true,
    child: Text(
      text,
      style: AppTheme.bodyTextStyle.copyWith(color: AppColors.primaryRed),
    ),
  );
}
