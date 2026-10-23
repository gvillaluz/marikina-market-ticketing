import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class VendorTicketPaperField extends StatelessWidget {
  final String label;
  final String value;
  final Widget? valueWidget;
  const VendorTicketPaperField({
    required this.label,
    required this.value,
    this.valueWidget,
    super.key,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final labelText = Text(label, style: AppTheme.ticketPaperLabelStyle);
      final content =
          valueWidget ??
          Text(
            value.trim().isEmpty ? 'Not provided' : value,
            style: AppTheme.ticketPaperValueStyle,
          );
      if (constraints.maxWidth < AppTheme.ticketPaperFieldBreakpoint ||
          MediaQuery.textScalerOf(context).scale(AppTheme.bodyFontSize) >
              AppTheme.sectionHeadingFontSize) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            labelText,
            const SizedBox(height: AppTheme.ticketTinyGap),
            content,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: labelText),
          const SizedBox(width: AppTheme.ticketSmallGap),
          Expanded(flex: 3, child: content),
        ],
      );
    },
  );
}
