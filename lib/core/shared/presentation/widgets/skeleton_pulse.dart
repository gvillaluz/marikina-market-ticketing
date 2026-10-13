import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class SkeletonPulse extends StatefulWidget {
  final Widget child;

  const SkeletonPulse({required this.child, super.key});

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppTheme.skeletonDuration,
  );
  late final Animation<double> _opacity = _controller.drive(
    Tween<double>(
      begin: AppTheme.skeletonMinOpacity,
      end: 1,
    ).chain(CurveTween(curve: Curves.easeInOut)),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shouldAnimate =
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (shouldAnimate) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: FadeTransition(opacity: _opacity, child: widget.child),
    ),
  );
}
