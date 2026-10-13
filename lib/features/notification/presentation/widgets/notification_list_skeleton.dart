import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/skeleton_box.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/skeleton_pulse.dart';

class NotificationListSkeleton extends StatelessWidget {
  final int itemCount;
  const NotificationListSkeleton({this.itemCount = 5, super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            ...List.generate(
              itemCount,
              (_) => const SkeletonBox(height: 80, animate: false),
            ),
          ],
        ),
      ),
    );
  }
}
