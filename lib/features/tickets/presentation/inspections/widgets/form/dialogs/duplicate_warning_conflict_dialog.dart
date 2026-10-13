import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';

class DuplicateWarningConflictDialog extends StatelessWidget {
  final String message;
  const DuplicateWarningConflictDialog({
    required this.message,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Center(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryYellow.withValues(alpha: .35),
            borderRadius: BorderRadius.circular(50)
          ),
          child: Icon(
            Icons.description_outlined,
            size: 40,
            color: AppColors.secondaryYellow,
          ),
        ),
      ),
      title: const Text(
        'Duplicate Warning',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold
        ), 
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(15),
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)
              ),
            ),
            onPressed: () {
              context.pop(true);
            }, 
            child: const Text(
              'Close',
              style: TextStyle(
                color: AppColors.primaryLight
              ),
            )
          ),
        )
      ],
    );
  }
}