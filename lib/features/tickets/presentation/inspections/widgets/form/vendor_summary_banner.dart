import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/vendor_summary.dart';

class VendorSummaryBanner extends StatelessWidget {
  final VendorSummary vendor;
  final VoidCallback onChangeVendor;
  const VendorSummaryBanner({
    required this.vendor,
    required this.onChangeVendor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lightGrey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: Row(
              spacing: 15,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.store,
                    color: AppColors.primaryLight,
                    size: 35,
                  ),
                ),
                Expanded(
                  child: Column(
                    spacing: 5,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendor.tradeName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text('Business ID: ${vendor.businessId}'),
                      Text('${vendor.lastName}, ${vendor.firstName}'),
                      Text(
                        '${vendor.stallNumber ?? 'No stall assigned'} \u2022 ${vendor.marketSectionName}',
                        style: TextStyle(color: AppColors.mediumGrey),
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
                shape: RoundedRectangleBorder(),
              ),
              onPressed: onChangeVendor,
              icon: const Icon(Icons.sync),
              label: const Text('Change Vendor'),
            ),
          ),
        ],
      ),
    );
  }
}
