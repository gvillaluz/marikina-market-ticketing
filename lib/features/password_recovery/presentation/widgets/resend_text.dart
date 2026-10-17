import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class ResendText extends StatelessWidget {
  final int cooldownSeconds;
  final bool isSending;
  final VoidCallback onResend;
  const ResendText({
    required this.cooldownSeconds,
    required this.isSending,
    required this.onResend,
    super.key,
  });
  String _format(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, "0")}:${(seconds % 60).toString().padLeft(2, "0")}';
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: AppTheme.authSmallGap,
      runSpacing: AppTheme.authSmallGap,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          "Didn't receive the code?",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.authVerificationBodyColor,
          ),
        ),
        TextButton(
          onPressed: isSending || cooldownSeconds > 0 ? null : onResend,
          child: Text(
            isSending
                ? 'Sending code...'
                : cooldownSeconds > 0
                ? 'Resend in ${_format(cooldownSeconds)}'
                : 'Resend code',
          ),
        ),
      ],
    ),
  );
}
