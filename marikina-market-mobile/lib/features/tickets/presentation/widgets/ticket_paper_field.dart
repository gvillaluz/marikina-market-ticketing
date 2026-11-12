import 'package:flutter/widgets.dart';

// One labelled line of a paper section. A TicketPaperFieldGroup draws it.
class TicketPaperField {
  final String label;
  final String value;
  final Widget? valueWidget;
  const TicketPaperField({
    required this.label,
    required this.value,
    this.valueWidget,
  });
}
