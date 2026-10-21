import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/skeleton_pulse.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class SkeletonBox extends StatelessWidget {
  final double height;
  final bool animate;

  const SkeletonBox({required this.height, this.animate = true, super.key});

  @override
  Widget build(BuildContext context) {
    final box = Container(
      height: height,
      margin: AppTheme.skeletonMargin,
      decoration: BoxDecoration(
        color: AppTheme.skeletonColor(context),
        borderRadius: AppTheme.controlRadius,
      ),
    );
    return animate ? SkeletonPulse(child: box) : ExcludeSemantics(child: box);
  }
}
