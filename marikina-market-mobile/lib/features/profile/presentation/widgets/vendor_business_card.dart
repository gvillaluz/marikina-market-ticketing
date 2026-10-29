import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/profile_detail_row.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/profile_info_card.dart';

class VendorBusinessCard extends StatelessWidget {
  final User user;
  const VendorBusinessCard({required this.user, super.key});
  @override
  Widget build(BuildContext context) {
    final vendor = user.vendor;
    return ProfileInfoCard(
      title: 'Registered business',
      children: vendor == null
          ? const [
              ProfileDetailRow(
                label: 'Business information unavailable',
                value: 'Sign in again to update your saved profile.',
              ),
            ]
          : [
              ProfileDetailRow(
                label: 'Business name',
                value: vendor.businessName,
              ),
              ProfileDetailRow(
                label: 'Business Account Number',
                value: vendor.businessAccountNumber,
              ),
              ProfileDetailRow(
                label: 'Stall Number',
                value: vendor.stallNumber,
              ),
              ProfileDetailRow(
                label: 'Market Section',
                value: vendor.marketSectionName,
              ),
              ProfileDetailRow(label: 'Business Type', value: vendor.type),
              ProfileDetailRow(label: 'Account Status', status: user.status),
            ],
    );
  }
}
