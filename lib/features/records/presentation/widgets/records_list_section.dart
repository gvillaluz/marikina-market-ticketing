import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/skeleton_box.dart';
import '../bloc/records/records_bloc.dart';
import '../bloc/records/records_state.dart';
import 'record_card.dart';
import 'records_notice.dart';

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
          padding: AppTheme.recordsPagePadding,
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
        return SliverMainAxisGroup(
          slivers: [
            if (state.error == null)
              SliverPadding(
                padding: AppTheme.recordsSummaryPadding,
                sliver: SliverToBoxAdapter(
                  child: Text(
                    '${state.total} records',
                    style: AppTheme.recordsCaptionStyle,
                  ),
                ),
              ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: RecordsNotice(
                message:
                    state.error ??
                    (state.search.isEmpty
                        ? 'No records found.'
                        : 'No records match your search.'),
                onRetry: state.error == null ? null : onRetry,
                icon: state.error == null
                    ? Icons.description_outlined
                    : Icons.cloud_off_outlined,
              ),
            ),
          ],
        );
      }
      return SliverMainAxisGroup(
        slivers: [
          SliverPadding(
            padding: AppTheme.recordsSummaryPadding,
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${state.total} record${state.total == 1 ? '' : 's'}',
                      style: AppTheme.recordsCaptionStyle,
                    ),
                  ),
                  if (state.isRefreshing) _progress(context),
                ],
              ),
            ),
          ),
          if (state.error != null && !state.isLoadMoreError)
            SliverToBoxAdapter(
              child: RecordsNotice(
                message: state.error!,
                onRetry: onRetry,
                icon: Icons.cloud_off_outlined,
              ),
            ),
          SliverPadding(
            padding: AppTheme.recordsListPadding,
            sliver: SliverList.builder(
              itemCount: state.items.length,
              itemBuilder: (context, index) => Padding(
                padding: AppTheme.selectionSheetItemPadding,
                child: RecordCard(
                  key: ValueKey(state.items[index].ticketId),
                  record: state.items[index],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: state.isLoadingMore
                ? Center(
                    child: Padding(
                      padding: AppTheme.recordsPagePadding,
                      child: _progress(context),
                    ),
                  )
                : state.isLoadMoreError
                ? RecordsNotice(
                    message: state.error ?? 'Unable to load more records.',
                    onRetry: onRetry,
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
