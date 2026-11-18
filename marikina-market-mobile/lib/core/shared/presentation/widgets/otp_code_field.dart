import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:pinput/pinput.dart';

const _codeLength = 6;

class OtpCodeField extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;

  /// The server refused the code: shake once and show red boxes until the
  /// person types again.
  final bool isWrong;

  /// The server accepted the code: the boxes turn green left to right.
  final bool isVerified;
  const OtpCodeField({
    super.key,
    required this.controller,
    required this.enabled,
    this.isWrong = false,
    this.isVerified = false,
  });

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField>
    with TickerProviderStateMixin {
  late final _shake = AnimationController(vsync: this);
  late final _success = AnimationController(vsync: this);
  late bool _showWrong = widget.isWrong;
  late String _wrongText = widget.controller.text;

  static final _successLength =
      AppTheme.authCodeSuccessStagger * (_codeLength - 1) +
      AppTheme.authCodeSuccessBoxDuration;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTyped);
    if (widget.isVerified) _success.value = 1;
  }

  @override
  void didUpdateWidget(covariant OtpCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTyped);
      widget.controller.addListener(_onTyped);
    }
    if (widget.isWrong && !oldWidget.isWrong) {
      _showWrong = true;
      _wrongText = widget.controller.text;
      _shake.duration = AppTheme.motionOf(
        context,
        AppTheme.authCodeShakeDuration,
      );
      _shake.forward(from: 0);
    } else if (!widget.isWrong) {
      _showWrong = false;
    }
    if (widget.isVerified && !oldWidget.isVerified) {
      _success.duration = AppTheme.motionOf(context, _successLength);
      _success.forward(from: 0);
    } else if (!widget.isVerified) {
      _success.value = 0;
    }
  }

  void _onTyped() {
    if (_showWrong && widget.controller.text != _wrongText) {
      setState(() => _showWrong = false);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTyped);
    _shake.dispose();
    _success.dispose();
    super.dispose();
  }

  // A damped side-to-side swing that ends where it started.
  double get _shakeOffset {
    final t = _shake.value;
    return math.sin(t * math.pi * 2 * AppTheme.authCodeShakeSwings) *
        AppTheme.authCodeShakeDistance *
        (1 - t);
  }

  // How green box [index] is (0 to 1): each box starts a little after the one
  // on its left.
  double _greenness(int index) {
    final total = _successLength.inMicroseconds;
    final start =
        (AppTheme.authCodeSuccessStagger * index).inMicroseconds / total;
    final end =
        start + AppTheme.authCodeSuccessBoxDuration.inMicroseconds / total;
    return Interval(
      start,
      end,
      curve: Curves.easeOut,
    ).transform(_success.value);
  }

  Widget _successBoxes(PinTheme pinTheme) => IgnorePointer(
    child: ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < _codeLength; i++) ...[
            if (i > 0) const SizedBox(width: AppTheme.authPinGap),
            Container(
              key: ValueKey('otp-success-box-$i'),
              width: pinTheme.width,
              height: pinTheme.height,
              decoration: BoxDecoration(
                borderRadius: AppTheme.authPinRadius,
                border: Border.all(
                  color: AppTheme.authCodeSuccessColor.withValues(
                    alpha: _greenness(i),
                  ),
                  width: AppTheme.authPinFocusBorderWidth,
                ),
                color: AppTheme.authCodeSuccessColor.withValues(
                  alpha: _greenness(i) * AppTheme.authCodeSuccessFillOpacity,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final theme = Theme.of(context);
      final pinTheme = PinTheme(
        width: ((constraints.maxWidth - AppTheme.authPinGap * 5) / 6)
            .clamp(0.0, AppTheme.authPinMaxWidth)
            .toDouble(),
        height:
            (MediaQuery.textScalerOf(
                      context,
                    ).scale(AppTheme.authPinTextStyle.fontSize!) +
                    AppTheme.authSmallGap * 2)
                .clamp(AppTheme.authPinHeight, double.infinity)
                .toDouble(),
        textStyle: AppTheme.authPinTextStyle.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        decoration: BoxDecoration(
          borderRadius: AppTheme.authPinRadius,
          border: Border.all(color: AppTheme.authPinBorderColor),
        ),
      );
      final errorPinTheme = pinTheme.copyDecorationWith(
        border: Border.all(color: theme.colorScheme.error),
      );
      final pinput = Pinput(
        animationDuration: AppTheme.motionOf(
          context,
          AppTheme.buttonAnimationDuration,
        ),
        // Each digit settles into its box with a small pop.
        animationCurve: Curves.easeOutBack,
        controller: widget.controller,
        enabled: widget.enabled,
        forceErrorState: _showWrong,
        length: _codeLength,
        keyboardType: TextInputType.number,
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(_codeLength),
        ],
        separatorBuilder: (index) => const SizedBox(width: AppTheme.authPinGap),
        defaultPinTheme: pinTheme,
        focusedPinTheme: pinTheme.copyDecorationWith(
          border: Border.all(
            color: theme.colorScheme.primary,
            width: AppTheme.authPinFocusBorderWidth,
          ),
        ),
        submittedPinTheme: pinTheme.copyDecorationWith(
          border: Border.all(color: theme.colorScheme.primary),
          color: theme.colorScheme.primary.withValues(alpha: 0.05),
        ),
        errorPinTheme: errorPinTheme,
        // Boxes locked after a wrong code keep the red border.
        disabledPinTheme: pinTheme.copyWith(
          textStyle: AppTheme.authPinTextStyle.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          decoration: BoxDecoration(
            borderRadius: AppTheme.authPinRadius,
            border: Border.all(
              color: _showWrong
                  ? theme.colorScheme.error
                  : AppTheme.authPinBorderColor,
            ),
            color: theme.colorScheme.surfaceContainerLow,
          ),
        ),
      );
      return AnimatedBuilder(
        animation: Listenable.merge([_shake, _success]),
        child: pinput,
        builder: (context, child) => Transform.translate(
          key: const ValueKey('otp-shake'),
          offset: Offset(_shakeOffset, 0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              child!,
              if (_success.value > 0)
                Positioned.fill(child: _successBoxes(pinTheme)),
            ],
          ),
        ),
      );
    },
  );
}
