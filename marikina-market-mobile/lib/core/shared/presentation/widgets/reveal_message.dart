import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

/// Opens and closes a form message smoothly so the form below glides
/// instead of jumping. A null [child] means no message.
class RevealMessage extends StatelessWidget {
  final Widget? child;
  const RevealMessage({this.child, super.key});

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: AppTheme.motionOf(context, AppTheme.formMotionEnterDuration),
    reverseDuration: AppTheme.motionOf(
      context,
      AppTheme.formMotionLeaveDuration,
    ),
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,
    layoutBuilder: (current, previous) => Stack(
      alignment: Alignment.topCenter,
      children: [...previous, ?current],
    ),
    transitionBuilder: (child, animation) => SizeTransition(
      sizeFactor: animation,
      alignment: Alignment.topCenter,
      child: FadeTransition(opacity: animation, child: child),
    ),
    child: child ?? const SizedBox(width: double.infinity),
  );
}
