import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/otp_code_field.dart';

class LoginOtpField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool isWrong;
  final bool isVerified;
  const LoginOtpField({
    required this.controller,
    required this.enabled,
    required this.isWrong,
    required this.isVerified,
    super.key,
  });
  @override
  Widget build(BuildContext context) => OtpCodeField(
    controller: controller,
    enabled: enabled,
    isWrong: isWrong,
    isVerified: isVerified,
  );
}
