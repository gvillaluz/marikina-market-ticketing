import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';

Widget buildSettlementCard({required Widget child}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.lightGrey.withValues(alpha: .5)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .06),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}

String formatSettlementHours(double hours) {
  if (hours == hours.roundToDouble()) return hours.toStringAsFixed(0);
  return hours.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
}
