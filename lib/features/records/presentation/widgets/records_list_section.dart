import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/skeleton_box.dart';
import '../bloc/records/records_bloc.dart';
import '../bloc/records/records_state.dart';
import 'record_card.dart';
import 'records_list_notice.dart';

class RecordsListSection extends StatelessWidget {
  final VoidCallback onRetry, onLoadMore;
  const RecordsListSection({
    required this.onRetry,
    required this.onLoadMore,
    super.key,
  });
  @override
  Widget build(BuildContext context) => BlocBuilder<RecordsBloc, RecordsState>(
    builder: (context, state) {
      if (state.isInitialLoading) {
        return SliverPadding(
          padding: AppTheme.inspectionListPadding,
          sliver: SliverList.list(
            children: [
              for (var i = 0; i < 3; i++)
                const Padding(
                  padding: AppTheme.selectionSheetItemPadding,
                  child: SkeletonBox(height: AppTheme.recordsSkeletonHeight),
                ),
            ],
          ),
        );
      }
      if (state.items.isEmpty) {
        return SliverPadding(
          padding: AppTheme.inspectionListPadding,
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                RecordsListNotice(
                  title: state.error == null
                      ? 'No records found'
                      : 'Unable to load records',
                  message: state.error == null
                      ? 'Try changing your search or record type. New records will appear here.'
                      : state.error!.trim().isEmpty
                      ? 'Please try again to load your records.'
                      : state.error!,
                  onRetry: state.error == null ? null : onRetry,
                  icon: state.error == null
                      ? Icons.assignment_outlined
                      : Icons.cloud_off_outlined,
                ),
                if (state.isRefreshing)
                  Padding(
                    padding: AppTheme.inspectionCardPadding,
                    child: _progress(context),
                  ),
              ],
            ),
          ),
        );
      }
      return SliverMainAxisGroup(
        slivers: [
          SliverPadding(
            padding: AppTheme.inspectionListPadding,
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: AppTheme.inspectionItemPadding,
                child: Text(
                  'Records • ${state.items.length}',
                  style: AppTheme.inspectionCaptionStyle.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          if (state.error != null && !state.isLoadMoreError)
            SliverPadding(
              padding: AppTheme.inspectionListPadding,
              sliver: SliverToBoxAdapter(
                child: RecordsListNotice(
                  title: 'Refresh failed',
                  message: state.error!.trim().isEmpty
                      ? 'Please try again.'
                      : state.error!,
                  onRetry: onRetry,
                  icon: Icons.cloud_off_outlined,
                ),
              ),
            ),
          SliverPadding(
            padding: AppTheme.inspectionListPadding,
            sliver: SliverList.builder(
              itemCount: state.items.length,
              itemBuilder: (context, index) => Padding(
                padding: AppTheme.inspectionItemPadding,
                child: RecordCard(
                  key: ValueKey(state.items[index].ticketId),
                  record: state.items[index],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: state.isLoadingMore || state.isRefreshing
                ? Center(
                    child: Padding(
                      padding: AppTheme.inspectionCardPadding,
                      child: _progress(context),
                    ),
                  )
                : state.isLoadMoreError
                ? Padding(
                    padding: AppTheme.inspectionListPadding,
                    child: RecordsListNotice(
                      title: 'Unable to load more records',
                      message:
                          state.error == null || state.error!.trim().isEmpty
                          ? 'Please try again.'
                          : state.error!,
                      icon: Icons.cloud_off_outlined,
                      onRetry: onRetry,
                    ),
                  )
                : state.hasMore
                ? TextButton(
                    onPressed: state.isRefreshing ? null : onLoadMore,
                    child: const Text('Load more records'),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      );
    },
  );
  Widget _progress(BuildContext context) => SizedBox.square(
    dimension: AppTheme.buttonIconSize,
    child: CircularProgressIndicator(
      value: MediaQuery.disableAnimationsOf(context) ? 0.75 : null,
      strokeWidth: AppTheme.buttonProgressStrokeWidth,
      semanticsLabel: 'Loading records',
    ),
  );
}
