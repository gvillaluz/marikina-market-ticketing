import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_primary_btn.dart';
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

  const TicketViolationCard({
    super.key,
    required this.onPressed,
    required this.onDelete,
    required this.ordinances,
    required this.capturedPhotos,
    required this.fineSummary,
    required this.isTicket,
    required this.errorMessage
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'VIOLATION',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold
          ),
        ),

        const Divider(height: 20,),
        const Text(
          'ORDINANCE',
        ),
        const SizedBox(height: 5,),

        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: AppPrimaryButton(
            label: ordinances.isEmpty 
              ? 'Select Ordinance'
              : 'Edit Selection', 
            iconData: ordinances.isEmpty 
              ? Icons.add_circle
              : Icons.edit_note, 
            onPressed: () => onPressed(context)
          ),
        ),

        if (errorMessage != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const SizedBox(width: 15,),
              Text(
                errorMessage!,
                style: const TextStyle(
                  color: AppColors.primaryRed,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 10,),

        if (ordinances.isNotEmpty) ...[
          FineSummarySection(
            items: ordinances,
            fineSummary: fineSummary,
            isTicket: isTicket,
            onDelete: onDelete,
          ),
          const SizedBox(height: 20,),
        ],

        const SizedBox(height: 10,)
      ]
    );
  }
}