import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_notice.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/duplicate_ordinance.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_detail_content_data.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_settlement_data.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/bloc/ticket_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/bloc/ticket_state.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/bloc/ticket_event.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_detail_content.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/skeleton_box.dart';

class TicketDetailPage extends StatelessWidget {
  final int? ticketId;
  final List<DuplicateOrdinance>? droppedOrdinances;

  const TicketDetailPage({this.ticketId, this.droppedOrdinances, super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        context.goNamed(Routes.inspectionsName);
      },
      child: Scaffold(
        backgroundColor: AppTheme.ticketDetailBackground,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.goNamed(Routes.inspectionsName);
              }
            },
          ),
          title: const Text(
            'Ticket Details',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppTheme.ticketDetailMaxWidth,
              ),
              child: SingleChildScrollView(
                padding: AppTheme.ticketDetailPadding,
                child: BlocConsumer<TicketBloc, TicketState>(
                  listenWhen: (previous, current) {
                    return current is TicketDetailLoaded &&
                        current.settlementMessage != null &&
                        (previous is! TicketDetailLoaded ||
                            previous.settlementMessage !=
                                current.settlementMessage);
                  },
                  listener: (context, state) {
                    if (state is TicketDetailLoaded &&
                        state.settlementMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.settlementMessage!)),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is TicketInitial ||
                        state is TicketDetailLoading) {
                      return const SkeletonBox(
                        height: AppTheme.ticketDetailSkeletonHeight,
                      );
                    }

                    if (state is TicketDetailLoaded) {
                      return TicketDetailContent(
                        data: TicketDetailContentData(
                          ticket: state.ticket,
                          droppedOrdinances: droppedOrdinances,
                          settlement: state.ticket.ticketStatus == null
                              ? null
                              : TicketSettlementData(
                                  ticketId: state.ticket.ticketId,
                                  penaltyType:
                                      state.ticket.penaltyType ??
                                      PenaltyType.cashFine,
                                  ticketStatus: state.ticket.ticketStatus!,
                                  requiredHours:
                                      state.ticket.communityServiceHours,
                                  receiptProof: state.receiptProof,
                                  isReceiptSubmitted: state.isReceiptSubmitted,
                                  communityServiceProgress:
                                      state.communityServiceProgress,
                                  isLoading: state.isSettlementLoading,
                                  isLoaded: state.isSettlementLoaded,
                                  isSubmitting: state.isSubmittingSettlement,
                                ),
                        ),
                        onRetrySettlementLoad: () {
                          if (state.ticket.penaltyType ==
                              PenaltyType.communityService) {
                            context.read<TicketBloc>().add(
                              LoadTicketDetail(state.ticket.ticketId),
                            );
                            return;
                          }
                          context.read<TicketBloc>().add(
                            LoadTicketSettlement(
                              ticketId: state.ticket.ticketId,
                              penaltyType:
                                  state.ticket.penaltyType ??
                                  PenaltyType.cashFine,
                            ),
                          );
                        },
                        onSubmitReceipt: (proofFile) {
                          context.read<TicketBloc>().add(
                            SubmitTicketReceiptProof(
                              ticketId: state.ticket.ticketId,
                              proofFile: proofFile,
                            ),
                          );
                        },
                        onSubmitCommunityServiceLog: (params) {
                          context.read<TicketBloc>().add(
                            SubmitCommunityServiceLog(params),
                          );
                        },
                      );
                    }

                    if (state is TicketError) {
                      return TicketNotice(
                        title: 'Unable to load ticket details',
                        message: state.message.trim().isEmpty
                            ? 'Please try again to load this ticket.'
                            : state.message,
                        icon: Icons.cloud_off_outlined,
                        onRetry: ticketId == null
                            ? null
                            : () => context.read<TicketBloc>().add(
                                LoadTicketDetail(ticketId!),
                              ),
                      );
                    }

                    return SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
