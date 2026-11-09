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
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.lightGrey),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            spacing: 15,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  color: AppColors.primaryLight,
                  size: 35,
                ),
              ),
              Expanded(
                child: Column(
                  spacing: 5,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      unregisteredVendorLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: AppTheme.sectionHeadingFontSize,
                      ),
                    ),
                    Text(
                      section.name,
                      style: const TextStyle(color: AppColors.mediumGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.all(10),
              iconSize: 25,
              shape: const RoundedRectangleBorder(),
            ),
            onPressed: onChangeSection,
            icon: const Icon(Icons.sync),
            label: const Text('Change section'),
          ),
        ),
      ],
    ),
  );
}
