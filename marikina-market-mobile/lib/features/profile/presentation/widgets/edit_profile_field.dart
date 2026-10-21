import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class EditProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final bool requiredField;
  final bool readOnly;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final String? hintText;
  final int? maxLength;

  const EditProfileField({
    super.key,
    required this.label,
    required this.controller,
    required this.enabled,
    this.requiredField = true,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.onTap,
    this.suffixIcon,
    this.hintText,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppTheme.profileGap),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppTheme.profileSmallGap),
        TextFormField(
          key: ValueKey(label),
          controller: controller,
          enabled: enabled,
          readOnly: readOnly,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: suffixIcon,
          ),
          onTap: onTap,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          validator: (value) {
            if (requiredField && (value == null || value.trim().isEmpty)) {
              return 'This field is required.';
            }
            final limit = maxLength;
            if (limit != null && (value?.trim().length ?? 0) > limit) {
              return 'Use at most $limit characters.';
            }
            return validator?.call(value);
          },
        ),
      ],
    ),
  );
}
