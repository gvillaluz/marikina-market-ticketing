import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class LoginFields extends StatefulWidget {
  final bool enabled;
  final VoidCallback? onSubmitted;
  final VoidCallback? onForgotPassword;
  final TextEditingController usernameController;
  final TextEditingController passwordController;

  const LoginFields({
    super.key,
    this.enabled = true,
    this.onSubmitted,
    this.onForgotPassword,
    required this.usernameController,
    required this.passwordController,
  });

  @override
  State<StatefulWidget> createState() => _LoginFieldsState();
}

class _LoginFieldsState extends State<LoginFields> {
  bool isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Screen readers hear the label as the box's name, not twice.
        const ExcludeSemantics(
          child: Text('Username', style: AppTheme.authFieldLabelStyle),
        ),
        const SizedBox(height: 7),
        Semantics(
          label: 'Username',
          child: TextField(
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            enabled: widget.enabled,
            controller: widget.usernameController,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            autocorrect: false,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.person_outline_rounded),

              hintText: 'Enter your username',
            ),
          ),
        ),

        const SizedBox(height: 20),

        const ExcludeSemantics(
          child: Text('Password', style: AppTheme.authFieldLabelStyle),
        ),
        const SizedBox(height: 7),
        Semantics(
          label: 'Password',
          child: TextField(
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            enabled: widget.enabled,
            controller: widget.passwordController,
            obscureText: !isPasswordVisible,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            autocorrect: false,
            enableSuggestions: false,
            onSubmitted: (_) => widget.onSubmitted?.call(),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: isPasswordVisible ? 'Hide password' : 'Show password',
                onPressed: !widget.enabled
                    ? null
                    : () => setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      }),
                icon: Icon(
                  isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
              hintText: 'Enter your password',
            ),
          ),
        ),
        // Under the password box, on the right, where it is looked for
        // after the password; screen readers reach it after the box too.
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: widget.onForgotPassword,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: const Text('Forgot password?', textAlign: TextAlign.end),
          ),
        ),
      ],
    );
  }
}
