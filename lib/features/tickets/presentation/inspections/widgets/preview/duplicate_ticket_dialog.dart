import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/duplicate_ordinance.dart';

class DuplicateTicketDialog extends StatelessWidget {
  final String message;
  final List<DuplicateOrdinance> duplicateOrdinances;
  final VoidCallback onEditOrdinances;

  const DuplicateTicketDialog({
    required this.message,
    required this.duplicateOrdinances,
    required this.onEditOrdinances,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryRed.withValues(alpha: .10),
              ),
              child: const Icon(
                Icons.close,
                color: AppColors.primaryRed,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ticket not created',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.mediumGrey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.lightGrey, width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: duplicateOrdinances.map((ordinance) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            ordinance.ordinanceNo,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ordinance.ordinanceCode,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.mediumGrey,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.primaryLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  onEditOrdinances();
                },
                child: const Text(
                  'Edit ordinances',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}