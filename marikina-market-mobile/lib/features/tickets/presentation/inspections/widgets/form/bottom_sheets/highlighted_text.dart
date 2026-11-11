import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

// Text with every match of [query] bolded, ignoring capitals. The query is
// matched as plain text, never as a pattern. A [prefix] such as "Stall " is
// shown first and never highlighted.
class HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final String prefix;
  final TextStyle? style;

  const HighlightedText({
    required this.text,
    required this.query,
    this.prefix = '',
    this.style,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final matchStyle = TextStyle(
      fontWeight: AppTheme.selectionMatchWeight,
      color: Theme.of(context).colorScheme.primary,
    );
    final matches = query.isEmpty
        ? const <RegExpMatch>[]
        : RegExp(
            RegExp.escape(query),
            caseSensitive: false,
          ).allMatches(text).toList();
    final spans = <TextSpan>[];
    var from = 0;
    for (final match in matches) {
      if (match.start > from) {
        spans.add(TextSpan(text: text.substring(from, match.start)));
      }
      spans.add(TextSpan(text: match.group(0), style: matchStyle));
      from = match.end;
    }
    if (from < text.length) spans.add(TextSpan(text: text.substring(from)));
    return Text.rich(
      TextSpan(text: prefix, children: spans),
      style: style,
    );
  }
}
