import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/ticket_paper_field.dart';

// A run of labelled lines that share one layout. Side by side, every label
// sits in one column as wide as the longest label, so all values start at the
// same left edge. The whole group stacks (label above value) on a narrow
// section, with enlarged text, or when the longest one-line label would leave
// the values too little room.
class TicketPaperFieldGroup extends StatelessWidget {
  final List<TicketPaperField> fields;
  final double spacing;

  const TicketPaperFieldGroup({
    required this.fields,
    required this.spacing,
    super.key,
  });

  // Width of the longest label on one line, in the style the Text renders it.
  // Text turns bold when the phone's "Bold text" setting is on, so measure that.
  double _widestLabel(BuildContext context) {
    var style = DefaultTextStyle.of(
      context,
    ).style.merge(AppTheme.ticketPaperLabelStyle);
    if (MediaQuery.boldTextOf(context)) {
      style = style.merge(const TextStyle(fontWeight: FontWeight.bold));
    }
    final direction = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    var widest = 0.0;
    for (final field in fields) {
      final painter = TextPainter(
        text: TextSpan(text: field.label, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      if (painter.width > widest) widest = painter.width;
      painter.dispose();
    }
    return widest;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final widest = _widestLabel(context);
      final stacked =
          constraints.maxWidth < AppTheme.ticketPaperFieldBreakpoint ||
          MediaQuery.textScalerOf(context).scale(AppTheme.bodyFontSize) >
              AppTheme.sectionHeadingFontSize ||
          widest +
                  AppTheme.ticketSmallGap +
                  AppTheme.ticketPaperFieldMinValueWidth >
              constraints.maxWidth;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing,
        children: [for (final field in fields) _row(field, stacked, widest)],
      );
    },
  );

  Widget _row(TicketPaperField field, bool stacked, double labelWidth) {
    final label = Text(field.label, style: AppTheme.ticketPaperLabelStyle);
    final value =
        field.valueWidget ??
        Text(field.value, style: AppTheme.ticketPaperValueStyle);
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          label,
          const SizedBox(height: AppTheme.ticketTinyGap),
          value,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: labelWidth, child: label),
        const SizedBox(width: AppTheme.ticketSmallGap),
        Expanded(child: value),
      ],
    );
  }
}
