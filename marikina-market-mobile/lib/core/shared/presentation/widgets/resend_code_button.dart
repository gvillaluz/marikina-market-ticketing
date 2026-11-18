import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

/// "Resend in 00:26" with a small ring that fills as the wait runs down;
/// when the wait is over it becomes an underlined "Resend code" link.
/// A null [onResend] means resending is not possible right now.
class ResendCodeButton extends StatefulWidget {
  final int secondsLeft;
  final bool isSending;
  final VoidCallback? onResend;
  const ResendCodeButton({
    required this.secondsLeft,
    required this.isSending,
    required this.onResend,
    super.key,
  });

  @override
  State<ResendCodeButton> createState() => _ResendCodeButtonState();
}

class _ResendCodeButtonState extends State<ResendCodeButton> {
  // The length of the current wait: the highest value seen since it started.
  late int _waitSeconds = widget.secondsLeft;

  @override
  void didUpdateWidget(covariant ResendCodeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.secondsLeft > oldWidget.secondsLeft) {
      _waitSeconds = widget.secondsLeft;
    }
  }

  String _format(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final waiting = !widget.isSending && widget.secondsLeft > 0;
    final canResend =
        widget.onResend != null && !widget.isSending && widget.secondsLeft == 0;
    final filled = _waitSeconds == 0
        ? 1.0
        : 1 - widget.secondsLeft / _waitSeconds;
    return TextButton(
      onPressed: canResend ? widget.onResend : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (waiting) ...[
            ExcludeSemantics(
              child: SizedBox.square(
                dimension: AppTheme.authResendRingSize,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: filled),
                  duration: AppTheme.motionOf(
                    context,
                    AppTheme.authResendRingStep,
                  ),
                  builder: (context, value, child) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: AppTheme.authResendRingStrokeWidth,
                    color: Theme.of(context).colorScheme.primary,
                    backgroundColor: AppTheme.authPinBorderColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.authResendRingGap),
          ],
          Flexible(
            child: Text(
              widget.isSending
                  ? 'Sending code...'
                  : waiting
                  ? 'Resend in ${_format(widget.secondsLeft)}'
                  : 'Resend code',
              style: canResend
                  ? const TextStyle(decoration: TextDecoration.underline)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
