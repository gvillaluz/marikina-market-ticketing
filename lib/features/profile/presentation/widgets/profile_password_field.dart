import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class ProfilePasswordField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool enabled;
  final bool isNewPassword;
  final VoidCallback? onSubmitted;
  const ProfilePasswordField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.enabled,
    this.isNewPassword = true,
    this.onSubmitted,
    super.key,
  });
  @override
  State<ProfilePasswordField> createState() => _ProfilePasswordFieldState();
}

class _ProfilePasswordFieldState extends State<ProfilePasswordField> {
  bool _visible = false;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        widget.label,
        style: AppTheme.bodyTextStyle.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: AppTheme.profileSmallGap),
      TextField(
        controller: widget.controller,
        enabled: widget.enabled,
        obscureText: !_visible,
        autocorrect: false,
        enableSuggestions: false,
        autofillHints: [
          widget.isNewPassword
              ? AutofillHints.newPassword
              : AutofillHints.password,
        ],
        textInputAction: widget.onSubmitted == null
            ? TextInputAction.next
            : TextInputAction.done,
        onSubmitted: widget.onSubmitted == null
            ? null
            : (_) => widget.onSubmitted!(),
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
        decoration: InputDecoration(
          hintText: widget.hint,
          suffixIcon: IconButton(
            tooltip: _visible ? 'Hide password' : 'Show password',
            onPressed: !widget.enabled
                ? null
                : () => setState(() => _visible = !_visible),
            icon: Icon(
              _visible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
          ),
        ),
      ),
    ],
  );
}
