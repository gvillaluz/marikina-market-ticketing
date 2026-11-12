import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/market_section.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/unregistered_vendor.dart';

// Shown in place of the business banner when the vendor is not registered.
class UnregisteredSectionBanner extends StatelessWidget {
  final MarketSection section;
  final VoidCallback onChangeSection;

  const UnregisteredSectionBanner({
    required this.section,
    required this.onChangeSection,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(left: AppTheme.inspectionSmallGap),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.lightGrey),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      spacing: AppTheme.inspectionSmallGap,
      children: [
        const Icon(
          Icons.storefront_outlined,
          color: AppColors.primary,
          size: AppTheme.inspectionIconSize,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                unregisteredVendorLabel,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                section.name,
                style: AppTheme.captionTextStyle.copyWith(
                  color: AppColors.mediumGrey,
                ),
              ),
            ],
          ),
        ),
        Tooltip(
          message: 'Change section',
          child: TextButton(
            onPressed: onChangeSection,
            child: const Text('Change'),
          ),
        ),
      ],
    ),
  );
}
