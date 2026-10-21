import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:pinput/pinput.dart';

class OtpCodeField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  const OtpCodeField({
    super.key,
    required this.controller,
    required this.enabled,
  });

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
      return Pinput(
        animationDuration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : AppTheme.buttonAnimationDuration,
        controller: controller,
        enabled: enabled,
        length: 6,
        keyboardType: TextInputType.number,
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
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
        errorPinTheme: pinTheme.copyDecorationWith(
          border: Border.all(color: theme.colorScheme.error),
        ),
        disabledPinTheme: pinTheme.copyWith(
          textStyle: AppTheme.authPinTextStyle.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          decoration: BoxDecoration(
            borderRadius: AppTheme.authPinRadius,
            border: Border.all(color: AppTheme.authPinBorderColor),
            color: theme.colorScheme.surfaceContainerLow,
          ),
        ),
      );
    },
  );
}
