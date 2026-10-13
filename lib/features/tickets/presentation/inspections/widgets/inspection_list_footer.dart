import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/inspection_list_notice.dart';

class InspectionListFooter extends StatelessWidget {
  final InspectionTicketsLoaded state;
  final VoidCallback? onRetry;
  const InspectionListFooter({required this.state, this.onRetry, super.key});

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore || state.isRefreshing) {
      return Padding(
        padding: AppTheme.inspectionCardPadding,
        child: Center(
          child: SizedBox.square(
            dimension: AppTheme.buttonIconSize,
            child: CircularProgressIndicator(
              value: MediaQuery.disableAnimationsOf(context) ? 0.75 : null,
              strokeWidth: AppTheme.buttonProgressStrokeWidth,
              semanticsLabel: state.isLoadingMore
                  ? 'Loading more inspections'
                  : 'Refreshing inspections',
              semanticsValue: 'In progress',
            ),
          ),
        ),
      );
    }
    if (state.errorMessage != null) {
      return Padding(
        padding: AppTheme.inspectionItemPadding,
        child: InspectionListNotice(
          title: state.isLoadMoreError
              ? 'Unable to load more inspections'
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
        padding: AppTheme.inspectionCardPadding,
        child: Center(
          child: Text(
            'All inspections loaded',
            style: AppTheme.inspectionCaptionStyle.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
