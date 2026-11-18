import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class AuthBtn extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSuccess;
  const AuthBtn({
    required this.onPressed,
    required this.isLoading,
    required this.label,
    this.isSuccess = false,
    super.key,
  });

  @override
  State<AuthBtn> createState() => _AuthBtnState();
}

class _AuthBtnState extends State<AuthBtn> {
  bool _pressed = false;

  // While the tick shows the button must stay blue (a null onPressed turns it
  // grey), but a second press must do nothing.
  static void _ignorePress() {}

  bool get _canPress =>
      widget.onPressed != null && !widget.isLoading && !widget.isSuccess;

  void _setPressed(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  Widget _content(BuildContext context) {
    if (widget.isSuccess) {
      return const Icon(
        Icons.check,
        key: ValueKey('success'),
        size: AppTheme.buttonIconSize,
        semanticLabel: 'Done',
      );
    }
    final label = Text(widget.label, textAlign: TextAlign.center);
    if (!widget.isLoading) {
      return KeyedSubtree(key: const ValueKey('idle'), child: label);
    }
    return Row(
      key: const ValueKey('loading'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox.square(
          dimension: AppTheme.buttonIconSize,
          child: CircularProgressIndicator(
            value: MediaQuery.disableAnimationsOf(context) ? 0.75 : null,
            strokeWidth: AppTheme.buttonProgressStrokeWidth,
            color: Theme.of(context).colorScheme.primary,
            semanticsLabel: 'Loading',
          ),
        ),
        const SizedBox(width: AppTheme.authSmallGap),
        Flexible(child: label),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: _canPress ? (_) => _setPressed(true) : null,
    onPointerUp: (_) => _setPressed(false),
    onPointerCancel: (_) => _setPressed(false),
    child: AnimatedScale(
      scale: _pressed && _canPress ? AppTheme.buttonPressScale : 1,
      duration: AppTheme.motionOf(context, AppTheme.buttonPressDuration),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: widget.isLoading
              ? null
              : widget.isSuccess
              ? _ignorePress
              : widget.onPressed,
          child: AnimatedSwitcher(
            duration: AppTheme.motionOf(
              context,
              AppTheme.buttonAnimationDuration,
            ),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(
                  begin: AppTheme.buttonContentOffset,
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: _content(context),
          ),
        ),
      ),
    ),
  );
}
