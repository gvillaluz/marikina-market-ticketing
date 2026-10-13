import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/utils/date_formatter_util.dart';
import 'package:marikina_market_mobile/features/auth/domain/entities/user.dart';
import 'package:marikina_market_mobile/features/profile/presentation/widgets/profile_detail_row.dart';

class ProfileAccountCard extends StatelessWidget {
  final User user;
  const ProfileAccountCard({required this.user, super.key});
  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      ProfileDetailRow(label: 'LAST NAME', value: user.lastName),
      ProfileDetailRow(label: 'FIRST NAME', value: user.firstName),
      ProfileDetailRow(label: 'MIDDLE NAME', value: user.middleName),
      ProfileDetailRow(
        label: 'DATE OF BIRTH',
        value: DateTimeFormatter.getDate(user.dateOfBirth),
      ),
      ProfileDetailRow(label: 'EMAIL', value: user.email),
      ProfileDetailRow(label: 'PHONE NUMBER', value: user.mobileNumber),
      ProfileDetailRow(label: 'ADDRESS', value: user.address),
      ProfileDetailRow(label: 'ACCOUNT STATUS', status: user.status),
      ProfileDetailRow(
        label: 'CREATED AT',
        value: DateTimeFormatter.getDate(user.createdAt),
      ),
    ];
    return Container(
      width: double.infinity,
      decoration: AppTheme.profileCardDecoration(context),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            if (index > 0) const Divider(height: 1),
            rows[index],
          ],
        ],
      ),
    );
  }
}
