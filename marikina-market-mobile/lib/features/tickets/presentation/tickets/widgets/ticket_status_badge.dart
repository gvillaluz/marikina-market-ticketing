import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/ticket_status.dart';

class TicketStatusBadge extends StatelessWidget {
  final TicketStatus status;
  const TicketStatusBadge({required this.status, super.key});
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppTheme.ticketStatusBackground(status.value),
      borderRadius: AppTheme.controlRadius,
    ),
    child: Padding(
      padding: AppTheme.ticketBadgePadding,
      child: Text(
        status.value,
        style: AppTheme.ticketCaptionStyle.copyWith(
          color: AppTheme.ticketStatusColor(status.value),
        ),
      ),
    ),
  );
}
