import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/profile_detail_row.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/profile_info_card.dart';

class ProfileAccountCard extends StatelessWidget {
  final User user;
  const ProfileAccountCard({required this.user, super.key});
  @override
  Widget build(BuildContext context) => ProfileInfoCard(
    title: 'Account information',
    children: [
      ProfileDetailRow(label: 'Username', value: user.username),
      ProfileDetailRow(label: 'Email', value: user.email),
      ProfileDetailRow(label: 'Contact number', value: user.mobileNumber),
      ProfileDetailRow(label: 'Address', value: user.address),
    ],
  );
}
