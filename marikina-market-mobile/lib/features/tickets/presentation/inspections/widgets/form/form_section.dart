import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

// A heading with the fields that belong under it, so the entry page reads as a
// few short groups.
class FormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const FormSection({required this.title, required this.children, super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(
        header: true,
        child: Text(title, style: AppTheme.inspectionHeadingStyle),
      ),
      const SizedBox(height: AppTheme.inspectionSmallGap),
      ...children,
    ],
  );
}
