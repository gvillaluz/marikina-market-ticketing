import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/skeleton_box.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_state.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/inspection_card.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/inspection_list_notice.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/inspection_list_footer.dart';

class InspectionListSection extends StatelessWidget {
  final VoidCallback? onRetry;
  const InspectionListSection({super.key, this.onRetry});

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<InspectionBloc, InspectionState>(
    builder: (context, state) {
      if (state is InspectionInitial ||
          state is InspectionLoading ||
          state is InspectionSilentLoading) {
        return SliverPadding(
          padding: AppTheme.inspectionListPadding,
          sliver: SliverList.builder(
            itemCount: 5,
            itemBuilder: (context, index) => const Padding(
              padding: AppTheme.inspectionItemPadding,
              child: SkeletonBox(height: AppTheme.inspectionSkeletonHeight),
            ),
          ),
        );
      }
      if (state is InspectionTicketsLoaded) {
        if (state.ticketSummary.isEmpty) {
          return SliverPadding(
            padding: AppTheme.inspectionListPadding,
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  const InspectionListNotice(
                    title: 'No inspections found',
                    message:
                        'Try changing your search or inspection type. New records will appear here.',
                    icon: Icons.assignment_outlined,
                  ),
                  InspectionListFooter(state: state, onRetry: onRetry),
                ],
              ),
            ),
          );
        }
        return SliverPadding(
          padding: AppTheme.inspectionListPadding,
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: AppTheme.inspectionItemPadding,
                    child: Text(
                      'Inspection records • ${state.ticketSummary.length}',
                      style: AppTheme.inspectionCaptionStyle.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                if (index == state.ticketSummary.length + 1) {
                  return InspectionListFooter(state: state, onRetry: onRetry);
                }
                final ticket = state.ticketSummary[index - 1];
                return Padding(
                  key: ValueKey(ticket.ticketId),
                  padding: AppTheme.inspectionItemPadding,
                  child: InspectionCard(ticketSummary: ticket),
                );
              },
              childCount: state.ticketSummary.length + 2,
              findChildIndexCallback: (key) {
                if (key is! ValueKey<int>) return null;
                final index = state.ticketSummary.indexWhere(
                  (ticket) => ticket.ticketId == key.value,
                );
                return index < 0 ? null : index + 1;
              },
            ),
          ),
        );
      }
      if (state is InspectionError) {
        return SliverPadding(
          padding: AppTheme.inspectionListPadding,
          sliver: SliverToBoxAdapter(
            child: InspectionListNotice(
              title: 'Unable to load inspections',
              message: state.message.trim().isEmpty
                  ? 'Please try again to load your inspections.'
                  : state.message,
              icon: Icons.cloud_off_outlined,
              onRetry: onRetry,
            ),
          ),
        );
      }
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    },
  );
}
