import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';

class LoginFields extends StatefulWidget {
  final bool enabled;
  final VoidCallback? onSubmitted;
  final TextEditingController usernameController;
  final TextEditingController passwordController;

  const LoginFields({
    super.key,
    this.enabled = true,
    this.onSubmitted,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('USERNAME'),
          const SizedBox(height: 7),
          TextField(
            enabled: widget.enabled,
            controller: widget.usernameController,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            autocorrect: false,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.person_rounded),

              hintText: 'Enter your username',
              hintStyle: TextStyle(color: AppColors.lightGrey, fontSize: 14),
            ),
          ),

          const SizedBox(height: 20),

          const Text('PASSWORD'),
          const SizedBox(height: 7),
          TextField(
            enabled: widget.enabled,
            controller: widget.passwordController,
            obscureText: !isPasswordVisible,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            autocorrect: false,
            enableSuggestions: false,
            onSubmitted: (_) => widget.onSubmitted?.call(),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.lock_rounded),
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
                      : Icons.visibility,
                ),
              ),
              hintText: 'Enter your password',
              hintStyle: TextStyle(color: AppColors.lightGrey, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
