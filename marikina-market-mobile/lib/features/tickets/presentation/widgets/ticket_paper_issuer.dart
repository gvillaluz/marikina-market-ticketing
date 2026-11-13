import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/utils/date_formatter_util.dart';

// The foot of the paper: the enforcer who issued it and the date, each on a
// writing line with a caption under it.
class TicketPaperIssuer extends StatelessWidget {
  final String enforcerName;
  final DateTime issuedAt;
  const TicketPaperIssuer({
    required this.enforcerName,
    required this.issuedAt,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    spacing: AppTheme.ticketSmallGap,
    children: [
      Expanded(
        flex: 3,
        child: _WritingLine(value: enforcerName, caption: 'Issuing enforcer'),
      ),
      Expanded(
        flex: 2,
        child: _WritingLine(
          value: DateTimeFormatter.getShortDate(issuedAt),
          caption: 'Date issued',
        ),
      ),
    ],
  );
}

class _WritingLine extends StatelessWidget {
  final String value, caption;
  const _WritingLine({required this.value, required this.caption});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.only(bottom: AppTheme.ticketTinyGap),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppTheme.ticketPaperValueStyle.color!,
              width: 1.5,
            ),
          ),
        ),
        child: Text(
          value,
          style: AppTheme.ticketPaperValueStyle.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(height: AppTheme.ticketTinyGap),
      Text(caption, style: AppTheme.ticketPaperLabelStyle),
    ],
  );
}
