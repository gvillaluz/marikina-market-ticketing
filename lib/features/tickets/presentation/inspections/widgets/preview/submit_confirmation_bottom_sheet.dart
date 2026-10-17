import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_primary_btn.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/utils/date_formatter_util.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_summary.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/inspection_severity_badge.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/preview/inspection_confirmation_detail.dart';

class SubmitConfirmationBottomSheet extends StatefulWidget {
  final VoidCallback onPressed;
  final FineSummary? fineSummary;
  final PenaltyType? penaltyType;
  final int? communityServiceHrs;
  final Severity? severity;
  final bool isTicket;
  const SubmitConfirmationBottomSheet({
    required this.onPressed,
    this.fineSummary,
    this.penaltyType,
    this.communityServiceHrs,
    this.severity,
    required this.isTicket,
    super.key,
  });
  @override
  State<SubmitConfirmationBottomSheet> createState() =>
      _SubmitConfirmationBottomSheetState();
}

class _SubmitConfirmationBottomSheetState
    extends State<SubmitConfirmationBottomSheet> {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '\u20b1',
  );
  bool _confirmed = false;
  void _confirm() {
    if (_confirmed) return;
    setState(() => _confirmed = true);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: AppTheme.inspectionCardPadding.add(
        EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppTheme.inspectionSmallGap,
        children: [
          Text(
            widget.isTicket
                ? 'Confirm ticket submission'
                : 'Confirm warning submission',
            style: AppTheme.inspectionHeadingStyle.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(
            'Review the details before issuing this inspection record.',
            style: AppTheme.inspectionBodyStyle,
          ),
          if (widget.isTicket &&
              widget.fineSummary != null &&
              widget.penaltyType != null) ...[
            if (widget.penaltyType == PenaltyType.cashFine)
              InspectionConfirmationDetail(
                label: 'Total fine due',
                value: _currencyFormat.format(
                  widget.fineSummary!.totalPaymentAmount,
                ),
              ),
            InspectionConfirmationDetail(
              label: 'Penalty type',
              value: widget.penaltyType!.label,
            ),
            if (widget.communityServiceHrs != null &&
                widget.communityServiceHrs! > 0)
              InspectionConfirmationDetail(
                label: 'Service hours',
                value: '${widget.communityServiceHrs} hrs',
              ),
            if (widget.severity != null)
              Align(
                alignment: Alignment.centerLeft,
                child: InspectionSeverityBadge(severity: widget.severity!),
              ),
            InspectionConfirmationDetail(
              label: 'Due date',
              value:
                  '${DateTimeFormatter.getDate(DateTime.now().add(const Duration(days: 5)))} (5 days from issuance)',
            ),
            const Divider(),
            Text(
              'This violation ticket will be issued and recorded.',
              style: AppTheme.inspectionBodyStyle,
            ),
          ],
          AppPrimaryButton(
            label: widget.isTicket
                ? widget.penaltyType == PenaltyType.cashFine
                      ? 'Issue ticket ${_currencyFormat.format(widget.fineSummary?.totalPaymentAmount ?? 0)}'
                      : 'Confirm ${widget.penaltyType?.label ?? "ticket"}'
                : 'Confirm warning',
            iconData: Icons.check_circle_outline,
            onPressed: _confirmed ? null : _confirm,
          ),
          OutlinedButton(
            onPressed: _confirmed ? null : () => Navigator.pop(context),
            child: const Text('Back'),
          ),
        ],
      ),
    ),
  );
}
