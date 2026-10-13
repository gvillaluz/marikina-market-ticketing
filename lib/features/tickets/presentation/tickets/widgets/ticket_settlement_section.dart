import 'dart:io';

import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/submit_community_service_log_params.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_settlement_data.dart';
import 'package:marikina_market_mobile/core/shared/domain/enums/penalty_type.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/community_service_log_section.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/settlement_receipt_section.dart';

class TicketSettlementSection extends StatelessWidget {
  final TicketSettlementData settlement;
  final VoidCallback onRetryLoad;
  final ValueChanged<File> onSubmitReceipt;
  final ValueChanged<SubmitCommunityServiceLogParams>
  onSubmitCommunityServiceLog;

  const TicketSettlementSection({
    required this.settlement,
    required this.onSubmitReceipt,
    required this.onSubmitCommunityServiceLog,
    required this.onRetryLoad,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (settlement.penaltyType == PenaltyType.communityService) {
      return CommunityServiceLogSection(
        settlement: settlement,
        onRetryLoad: onRetryLoad,
        onSubmit: onSubmitCommunityServiceLog,
      );
    }

    return SettlementReceiptSection(
      settlement: settlement,
      onRetryLoad: onRetryLoad,
      onSubmit: onSubmitReceipt,
    );
  }
}
