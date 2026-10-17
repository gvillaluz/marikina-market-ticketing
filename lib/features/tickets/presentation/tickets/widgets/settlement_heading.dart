import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class SettlementHeading extends StatelessWidget {
  final String title;
  final String description;

  const SettlementHeading({
    required this.title,
    required this.description,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.detailTitleStyle.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(description),
      ],
    );
  }
}
