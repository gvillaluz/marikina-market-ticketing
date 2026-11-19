import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/password_rule_checklist.dart';

class ResetPasswordFields extends StatefulWidget {
  final TextEditingController newPasswordController;
  final TextEditingController confirmNewPasswordController;
  final bool enabled;

  const ResetPasswordFields({
    required this.newPasswordController,
    required this.confirmNewPasswordController,
    this.enabled = true,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _ResetPasswordFieldsState();
}

class _ResetPasswordFieldsState extends State<ResetPasswordFields> {
  bool isNewPasswordVisible = false;
  bool isConfirmNewPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('New password', style: AppTheme.authFieldLabelStyle),
        const SizedBox(height: 7),
        TextField(
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          enabled: widget.enabled,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: const [AutofillHints.newPassword],
          textInputAction: TextInputAction.next,
          controller: widget.newPasswordController,
          obscureText: !isNewPasswordVisible,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              tooltip: isNewPasswordVisible ? 'Hide password' : 'Show password',
              onPressed: !widget.enabled
                  ? null
                  : () => setState(() {
                      isNewPasswordVisible = !isNewPasswordVisible;
                    }),
              icon: Icon(
                isNewPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
            hintText: 'Enter your new password',
          ),
        ),

        const SizedBox(height: 7),
        PasswordRuleChecklist(controller: widget.newPasswordController),

        const SizedBox(height: 20),

        const Text('Confirm new password', style: AppTheme.authFieldLabelStyle),
        const SizedBox(height: 7),
        TextField(
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          enabled: widget.enabled,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: const [AutofillHints.newPassword],
          textInputAction: TextInputAction.done,
          controller: widget.confirmNewPasswordController,
          obscureText: !isConfirmNewPasswordVisible,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              tooltip: isConfirmNewPasswordVisible
                  ? 'Hide password'
                  : 'Show password',
              onPressed: !widget.enabled
                  ? null
                  : () => setState(() {
                      isConfirmNewPasswordVisible =
                          !isConfirmNewPasswordVisible;
                    }),
              icon: Icon(
                isConfirmNewPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
            hintText: 'Confirm your new password',
          ),
        ),
      ],
    );
  }
}
