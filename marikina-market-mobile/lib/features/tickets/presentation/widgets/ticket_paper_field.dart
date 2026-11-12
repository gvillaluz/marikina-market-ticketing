import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class TicketPaperField extends StatelessWidget {
  final String label;
  final String value;
  final Widget? valueWidget;
  const TicketPaperField({
    required this.label,
    required this.value,
    this.valueWidget,
    super.key,
  });

  // Width of the label on one line, in the style the Text below renders it.
  double _labelWidth(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: DefaultTextStyle.of(
          context,
        ).style.merge(AppTheme.ticketPaperLabelStyle),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final labelText = Text(label, style: AppTheme.ticketPaperLabelStyle);
      final content =
          valueWidget ?? Text(value, style: AppTheme.ticketPaperValueStyle);
      // Stack the label above the value on narrow rows, with enlarged text,
      // or when the one-line label would leave the value too little room.
      if (constraints.maxWidth < AppTheme.ticketPaperFieldBreakpoint ||
          MediaQuery.textScalerOf(context).scale(AppTheme.bodyFontSize) >
              AppTheme.sectionHeadingFontSize ||
          _labelWidth(context) +
                  AppTheme.ticketSmallGap +
                  AppTheme.ticketPaperFieldMinValueWidth >
              constraints.maxWidth) {
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
          labelText,
          const SizedBox(width: AppTheme.ticketSmallGap),
          Expanded(child: content),
        ],
      );
    },
  );
}
