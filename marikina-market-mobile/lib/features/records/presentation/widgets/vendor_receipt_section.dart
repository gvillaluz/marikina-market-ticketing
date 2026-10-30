import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import '../bloc/vendor_settlement/vendor_settlement_state.dart';
import 'vendor_settlement_photo.dart';

class VendorReceiptSection extends StatelessWidget {
  final VendorSettlementState settlement;
  const VendorReceiptSection({required this.settlement, super.key});

  @override
  Widget build(BuildContext context) {
    final urls = settlement.receipt?.proofUrls ?? const <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final url in urls)
          VendorSettlementPhoto(url: url, title: 'Settlement receipt'),
        Text(
          urls.isEmpty
              ? 'No settlement receipt has been submitted.'
              : 'Settlement receipt is read-only.',
          style: AppTheme.inspectionBodyStyle,
        ),
      ],
    );
  }
}
