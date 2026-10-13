import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';

class ChangePasswordFields extends StatefulWidget {
  final bool enabled;
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmNewPasswordController;

  const ChangePasswordFields({
    super.key,
    this.enabled = true,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmNewPasswordController,
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CURRENT PASSWORD'),
          const SizedBox(height: 7),
          TextField(
            enabled: widget.enabled,
            autocorrect: false,
            enableSuggestions: false,
            controller: widget.currentPasswordController,
            obscureText: !isCurrentPasswordVisible,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.lock_rounded),
              suffixIcon: IconButton(
                onPressed: !widget.enabled
                    ? null
                    : () => setState(() {
                        isCurrentPasswordVisible = !isCurrentPasswordVisible;
                      }),
                icon: Icon(
                  isCurrentPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility,
                ),
              ),
              hintText: 'Enter your current password',
              hintStyle: TextStyle(color: AppColors.lightGrey, fontSize: 14),
            ),
          ),

          const SizedBox(height: 20),

          const Text('NEW PASSWORD'),
          const SizedBox(height: 7),
          TextField(
            enabled: widget.enabled,
            autocorrect: false,
            enableSuggestions: false,
            controller: widget.newPasswordController,
            obscureText: !isNewPasswordVisible,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.lock_rounded),
              suffixIcon: IconButton(
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
              hintText: 'Enter your new password',
              hintStyle: TextStyle(color: AppColors.lightGrey, fontSize: 14),
            ),
          ),

          const SizedBox(height: 20),

          const Text('CONFIRM NEW PASSWORD'),
          const SizedBox(height: 7),
          TextField(
            enabled: widget.enabled,
            autocorrect: false,
            enableSuggestions: false,
            controller: widget.confirmNewPasswordController,
            obscureText: !isConfirmNewPasswordVisible,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.lock_rounded),
              suffixIcon: IconButton(
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
              hintText: 'Confirm your new password',
              hintStyle: TextStyle(color: AppColors.lightGrey, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
