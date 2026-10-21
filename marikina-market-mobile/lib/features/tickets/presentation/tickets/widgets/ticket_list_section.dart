import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/skeleton_box.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/bloc/ticket_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/bloc/ticket_state.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_card.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_notice.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_list_footer.dart';

class TicketListSection extends StatelessWidget {
  final VoidCallback? onRetry;
  const TicketListSection({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) => BlocBuilder<TicketBloc, TicketState>(
    builder: (context, state) {
      if (state is TicketInitial ||
          state is TicketLoading ||
          state is TicketSilentLoading) {
        return SliverPadding(
          padding: AppTheme.ticketListPadding,
          sliver: SliverList.builder(
            itemCount: 5,
            itemBuilder: (context, index) => const Padding(
              padding: AppTheme.ticketItemPadding,
              child: SkeletonBox(height: AppTheme.ticketSkeletonHeight),
            ),
          ),
        );
      }
      if (state is TicketsLoaded) {
        if (state.ticketSummary.isEmpty) {
          return SliverPadding(
            padding: AppTheme.ticketListPadding,
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  const TicketNotice(
                    title: 'No Tickets Found',
                    message:
                        'Try changing your search or ticket status. New records will appear here.',
                    icon: Icons.assignment_outlined,
                  ),
                  TicketListFooter(state: state, onRetry: onRetry),
                ],
              ),
            ),
          );
        }
        return SliverPadding(
          padding: AppTheme.ticketListPadding,
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: AppTheme.ticketItemPadding,
                    child: Text(
                      'Ticket records • ${state.ticketSummary.length}',
                      style: AppTheme.ticketCaptionStyle.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                if (index == state.ticketSummary.length + 1) {
                  return TicketListFooter(state: state, onRetry: onRetry);
                }
                final ticket = state.ticketSummary[index - 1];
                return Padding(
                  key: ValueKey(ticket.ticketId),
                  padding: AppTheme.ticketItemPadding,
                  child: TicketCard(ticketSummary: ticket),
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
      if (state is TicketError) {
        return SliverPadding(
          padding: AppTheme.ticketListPadding,
          sliver: SliverToBoxAdapter(
            child: TicketNotice(
              title: 'Unable to load tickets',
              message: state.message.trim().isEmpty
                  ? 'Please try again to load your tickets.'
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
