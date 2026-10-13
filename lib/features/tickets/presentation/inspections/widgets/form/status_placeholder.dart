import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';

class StatusPlaceholder extends StatelessWidget {
  final IconData? icon;
  final Widget? child;
  final String title;
  final String subtitle;

  const StatusPlaceholder({
    this.icon,
    this.child,
    required this.title,
    required this.subtitle,
    super.key
  }) : assert(icon != null || child != null, 'Provide either an icon or a custom child.');

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            child ??
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32, color: AppColors.primary),
                ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.mediumGrey,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}