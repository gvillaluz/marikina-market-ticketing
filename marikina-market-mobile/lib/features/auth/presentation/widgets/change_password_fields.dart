import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/password_rule_checklist.dart';
import 'package:marikina_market_mobile/core/utils/password_change_check.dart';

class ChangePasswordFields extends StatefulWidget {
  final bool enabled;
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmNewPasswordController;
  final PasswordChangeCheck? check;
  final VoidCallback onSubmitted;

  const ChangePasswordFields({
    super.key,
    this.enabled = true,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmNewPasswordController,
    this.check,
    required this.onSubmitted,
  });

  @override
  State<StatefulWidget> createState() => _ChangePasswordFieldsState();
}

class _ChangePasswordFieldsState extends State<ChangePasswordFields> {
  bool isCurrentPasswordVisible = false;
  bool isNewPasswordVisible = false;
  bool isConfirmNewPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.authGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ExcludeSemantics(child: Text('CURRENT PASSWORD')),
          const SizedBox(height: 7),
          Semantics(
            label: 'Current password',
            child: TextField(
              enabled: widget.enabled,
              autocorrect: false,
              enableSuggestions: false,
              controller: widget.currentPasswordController,
              obscureText: !isCurrentPasswordVisible,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.lock_rounded),
                suffixIcon: ExcludeFocus(
                  child: IconButton(
                    tooltip: isCurrentPasswordVisible
                        ? 'Hide current password'
                        : 'Show current password',
                    onPressed: !widget.enabled
                        ? null
                        : () => setState(() {
                            isCurrentPasswordVisible =
                                !isCurrentPasswordVisible;
                          }),
                    icon: Icon(
                      isCurrentPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility,
                    ),
                  ),
                ),
                hintText: 'Enter your current password',
                errorText: widget.check?.currentError,
              ),
            ),
          ),

          const SizedBox(height: 20),

          const ExcludeSemantics(child: Text('NEW PASSWORD')),
          const SizedBox(height: 7),
          Semantics(
            label: 'New password',
            child: TextField(
              enabled: widget.enabled,
              autocorrect: false,
              enableSuggestions: false,
              controller: widget.newPasswordController,
              obscureText: !isNewPasswordVisible,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.lock_rounded),
                suffixIcon: ExcludeFocus(
                  child: IconButton(
                    tooltip: isNewPasswordVisible
                        ? 'Hide new password'
                        : 'Show new password',
                    onPressed: !widget.enabled
                        ? null
                        : () => setState(() {
                            isNewPasswordVisible = !isNewPasswordVisible;
                          }),
                    icon: Icon(
                      isNewPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility,
                    ),
                  ),
                ),
                hintText: 'Enter your new password',
                errorText: widget.check?.newPasswordError,
              ),
            ),
          ),

          const SizedBox(height: 7),
          PasswordRuleChecklist(controller: widget.newPasswordController),

          const SizedBox(height: 20),

          const ExcludeSemantics(child: Text('CONFIRM NEW PASSWORD')),
          const SizedBox(height: 7),
          Semantics(
            label: 'Confirm new password',
            child: TextField(
              enabled: widget.enabled,
              autocorrect: false,
              enableSuggestions: false,
              controller: widget.confirmNewPasswordController,
              obscureText: !isConfirmNewPasswordVisible,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onSubmitted: (_) => widget.onSubmitted(),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.lock_rounded),
                suffixIcon: ExcludeFocus(
                  child: IconButton(
                    tooltip: isConfirmNewPasswordVisible
                        ? 'Hide confirm new password'
                        : 'Show confirm new password',
                    onPressed: !widget.enabled
                        ? null
                        : () => setState(() {
                            isConfirmNewPasswordVisible =
                                !isConfirmNewPasswordVisible;
                          }),
                    icon: Icon(
                      isConfirmNewPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility,
                    ),
                  ),
                ),
                hintText: 'Confirm your new password',
                errorText: widget.check?.confirmError,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
