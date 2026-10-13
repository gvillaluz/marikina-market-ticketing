import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';

class AutoFillBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const AutoFillBtn({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(15),
        side: BorderSide(
          color: AppColors.primary,
          width: 2
        ),
      ),
      onPressed: onPressed, 
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          Icon(
            icon,
            size: 30,
          ),
          Text(label)
        ],
      )
    ),
  );
}