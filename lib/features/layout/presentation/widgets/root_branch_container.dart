import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class RootBranchContainer extends StatefulWidget {
  final int currentIndex;
  final List<Widget> children;

  const RootBranchContainer({
    required this.currentIndex,
    required this.children,
    super.key,
  });

  @override
  State<RootBranchContainer> createState() => _RootBranchContainerState();
}

class _RootBranchContainerState extends State<RootBranchContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppTheme.tabTransitionDuration,
    value: 1,
  );
  late final Animation<double> _opacity = _controller.drive(
    Tween<double>(
      begin: AppTheme.tabInitialOpacity,
      end: 1,
    ).chain(CurveTween(curve: Curves.easeOutCubic)),
  );
  late final Animation<Offset> _position = _controller.drive(
    Tween<Offset>(
      begin: AppTheme.tabEntryOffset,
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic)),
  );
  bool _animationsEnabled = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animationsEnabled =
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (!_animationsEnabled) _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant RootBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      if (_animationsEnabled) {
        _controller.forward(from: 0);
      } else {
        _controller.value = 1;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRect(
    child: FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _position,
        child: Stack(
          fit: StackFit.expand,
          children: List.generate(
            widget.children.length,
            (index) => Offstage(
              key: ValueKey(index),
              offstage: index != widget.currentIndex,
              child: TickerMode(
                enabled: index == widget.currentIndex,
                child: ExcludeFocus(
                  excluding: index != widget.currentIndex,
                  child: RepaintBoundary(child: widget.children[index]),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
