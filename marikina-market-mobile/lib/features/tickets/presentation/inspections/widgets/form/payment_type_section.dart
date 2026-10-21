import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/severity.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';

class PaymentTypeSection extends StatefulWidget {
  final PenaltyType selectedPenaltyType;
  final Severity severity;
  final double totalFineAmount;
  final ValueChanged<PenaltyType> onChangeType;
  final TextEditingController communityHrsController;
  final String? communityHrsError;

  const PaymentTypeSection({
    super.key,
    required this.selectedPenaltyType,
    required this.severity,
    required this.totalFineAmount,
    required this.onChangeType,
    required this.communityHrsController,
    required this.communityHrsError,
  });

  @override
  State<StatefulWidget> createState() => _PaymentTypeSectionState();
}

class _PaymentTypeSectionState extends State<PaymentTypeSection> {
  late PenaltyType _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.severity == Severity.high
        ? PenaltyType.cashFine
        : widget.selectedPenaltyType;
  }

  @override
  void didUpdateWidget(covariant PaymentTypeSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selectedType = widget.severity == Severity.high
        ? PenaltyType.cashFine
        : widget.selectedPenaltyType;
  }

  @override
  Widget build(BuildContext context) {
    final isHighSeverity = widget.severity == Severity.high;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How the violator pays',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 5),

        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightGrey, width: 0.8),
          ),
          child: Column(
            children: [
              _buildOptionTile(
                value: PenaltyType.cashFine,
                title: 'Pay ₱${widget.totalFineAmount.toStringAsFixed(2)}',
              ),
              const Divider(height: 1, color: AppColors.lightGrey),

              _buildOptionTile(
                value: PenaltyType.communityService,
                title: 'Community service',
                trailingText: '3 hrs',
                disabled: isHighSeverity,
              ),
              const Divider(height: 1, color: AppColors.lightGrey),

              _buildOptionTile(
                value: PenaltyType.bloodDonation,
                title: 'Blood donation',
                disabled: isHighSeverity,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required PenaltyType value,
    required String title,
    String? trailingText,
    bool disabled = false,
  }) {
    final isSelected = _selectedType == value;
    final textColor = disabled ? AppColors.mediumGrey : AppColors.primaryBlack;

    return InkWell(
      onTap: disabled
          ? null
          : () {
              setState(() {
                _selectedType = value;
              });
              widget.onChangeType(value);
            },
      child: Opacity(
        opacity: disabled ? 0.55 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Custom Radio Circle
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: disabled
                        ? AppColors.mediumGrey
                        : isSelected
                        ? AppColors.primary
                        : AppColors.mediumGrey,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              if (_selectedType == PenaltyType.communityService &&
                  value == PenaltyType.communityService) ...[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: AppTheme.bodyFontSize,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'hours(minimum of 3 hours)',
                        style: TextStyle(
                          fontSize: AppTheme.captionFontSize,
                          color: widget.communityHrsError != null
                              ? AppColors.primaryRed
                              : AppColors.mediumGrey,
                        ),
                      ),
                      if (widget.communityHrsError != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.communityHrsError!,
                          style: const TextStyle(
                            fontSize: AppTheme.captionFontSize,
                            color: AppColors.primaryRed,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  spacing: 10,
                  children: [
                    SizedBox(
                      height: 35,
                      width: 50,
                      child: TextField(
                        controller: widget.communityHrsController,
                        enabled: !disabled,
                        textAlignVertical: TextAlignVertical.center,
                        textAlign: TextAlign.center,
                        onTapOutside: (event) =>
                            FocusScope.of(context).unfocus(),
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.zero,

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                              color: widget.communityHrsError != null
                                  ? AppColors.primaryRed
                                  : AppColors.lightGrey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      'hrs',
                      style: const TextStyle(
                        fontSize: AppTheme.sectionHeadingFontSize,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: AppTheme.bodyFontSize,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
