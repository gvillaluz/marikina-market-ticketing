import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/vendor_summary.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/detail_row.dart';

class ViolatorInfoSection extends StatelessWidget {
  final VendorSummary vendor;
  final bool isTicket;

  const ViolatorInfoSection({
    required this.vendor,
    required this.isTicket,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Wrap(
          spacing: AppTheme.inspectionTinyGap,
          children: [
            Icon(Icons.person, color: AppColors.primary),
            Text(
              'VIOLATOR DETAILS',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: AppTheme.sectionHeadingFontSize,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        DetailRow(label: "STALL/UNIT NO:", value: vendor.stallNumber ?? 'N/A'),
        const SizedBox(height: 10),
        DetailRow(label: "TRADE NAME:", value: vendor.tradeName),
        const SizedBox(height: 10),
        DetailRow(
          label: "NAME:",
          value: '${vendor.lastName}, ${vendor.firstName}',
        ),
        if (isTicket) ...[
          const SizedBox(height: 10),
          DetailRow(label: "ADDRESS:", value: vendor.address),
        ],
      ],
    );
  }
}
