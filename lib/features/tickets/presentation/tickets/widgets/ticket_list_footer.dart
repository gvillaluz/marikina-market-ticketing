import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/bloc/ticket_state.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_notice.dart';

class TicketListFooter extends StatelessWidget {
  final TicketsLoaded state;
  final VoidCallback? onRetry;
  const TicketListFooter({required this.state, this.onRetry, super.key});

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore || state.isRefreshing) {
      return Padding(
        padding: AppTheme.ticketCardPadding,
        child: Center(
          child: SizedBox.square(
            dimension: AppTheme.buttonIconSize,
            child: CircularProgressIndicator(
              value: MediaQuery.disableAnimationsOf(context) ? 0.75 : null,
              strokeWidth: AppTheme.buttonProgressStrokeWidth,
              semanticsLabel: state.isLoadingMore
                  ? 'Loading more tickets'
                  : 'Refreshing tickets',
              semanticsValue: 'In progress',
            ),
          ),
        ),
      );
    }
    if (state.errorMessage != null) {
      return Padding(
        padding: AppTheme.ticketItemPadding,
        child: TicketNotice(
          title: state.isLoadMoreError
              ? 'Unable to load more tickets'
              : 'Refresh failed',
          message: state.errorMessage!.trim().isEmpty
              ? 'Please try again.'
              : state.errorMessage!,
          icon: Icons.cloud_off_outlined,
          onRetry: onRetry,
        ),
      );
    }
    if (!state.hasMore && state.ticketSummary.isNotEmpty) {
      return Padding(
        padding: AppTheme.ticketCardPadding,
        child: Center(
          child: Text(
            'All tickets loaded',
            style: AppTheme.ticketCaptionStyle.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
