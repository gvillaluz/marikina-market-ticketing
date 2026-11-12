import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_outlined_btn.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ordinance.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/fine_summary_section.dart';

class TicketViolationCard extends StatelessWidget {
  final ValueChanged<BuildContext> onPressed;
  final ValueChanged<int> onDelete;
  final List<Ordinance> ordinances;
  final List<XFile> capturedPhotos;
  final FineSummary? fineSummary;
  final bool isTicket;
  final String? errorMessage;
  final Map<int, String> assessmentTexts;
  final void Function(int, String)? onAssessmentChanged;

  const TicketViolationCard({
    super.key,
    required this.onPressed,
    required this.onDelete,
    required this.ordinances,
    required this.capturedPhotos,
    required this.fineSummary,
    required this.isTicket,
    required this.errorMessage,
    this.assessmentTexts = const {},
    this.onAssessmentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ordinance', style: AppTheme.ticketPaperLabelStyle),
        const SizedBox(height: AppTheme.inspectionTinyGap),
        AppOutlinedBtn(
          label: ordinances.isEmpty ? 'Select ordinance' : 'Edit selection',
          iconData: ordinances.isEmpty ? Icons.add_circle : Icons.edit_note,
          onPressed: () => onPressed(context),
          foregroundColor: Theme.of(context).colorScheme.primary,
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),

        if (errorMessage != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: AppColors.primaryRed,
                    fontSize: AppTheme.captionFontSize,
                  ),
                ),
              ),
            ],
          ),
        ],

        if (ordinances.isNotEmpty) ...[
          const SizedBox(height: AppTheme.inspectionSmallGap),
          FineSummarySection(
            items: ordinances,
            fineSummary: fineSummary,
            isTicket: isTicket,
            onDelete: onDelete,
            assessmentTexts: assessmentTexts,
            onAssessmentChanged: onAssessmentChanged,
          ),
        ],
      ],
    );
  }
}
