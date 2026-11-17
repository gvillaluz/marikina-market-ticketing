import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/password_rule_line.dart';
import 'package:marikina_market_mobile/core/utils/password_change_check.dart';

/// The password rules under a new-password box, each ticked as it is met.
class PasswordRuleChecklist extends StatelessWidget {
  final TextEditingController controller;

  const PasswordRuleChecklist({required this.controller, super.key});

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final rule in PasswordChangeCheck.rules)
              PasswordRuleLine(label: rule.label, met: rule.met(value.text)),
          ],
        ),
      );
}
