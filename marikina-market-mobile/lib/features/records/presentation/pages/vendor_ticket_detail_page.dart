import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:marikina_market_mobile/core/router/routes.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/skeleton_box.dart';
import '../bloc/record_detail/record_detail_bloc.dart';
import '../bloc/record_detail/load_record_detail.dart';
import '../bloc/record_detail/record_detail_state.dart';
import '../widgets/records_notice.dart';
import '../widgets/vendor_record_detail_content.dart';
import '../widgets/vendor_settlement_section.dart';
import '../bloc/vendor_settlement/vendor_settlement_bloc.dart';
import '../bloc/vendor_settlement/load_vendor_settlement.dart';

class VendorTicketDetailPage extends StatelessWidget {
  final int ticketId;
  const VendorTicketDetailPage({required this.ticketId, super.key});
  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.vendorRecords);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) context.go(Routes.vendorRecords);
    },
    child: Scaffold(
      backgroundColor: AppTheme.ticketDetailBackground,
      appBar: AppBar(
        title: const Text(
          'Ticket Details',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          tooltip: 'Back to records',
          onPressed: () => _back(context),
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.primary,
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
              child: BlocConsumer<RecordDetailBloc, RecordDetailState>(
                listenWhen: (previous, current) =>
                    current.detail != null && current.detail != previous.detail,
                listener: (context, state) => context
                    .read<VendorSettlementBloc>()
                    .add(LoadVendorSettlement(state.detail!)),
                builder: (context, state) {
                  if (state.isLoading) {
                    return const SkeletonBox(
                      height: AppTheme.ticketDetailSkeletonHeight,
                    );
                  }
                  if (state.error != null) {
                    return RecordsNotice(
                      message: state.error!,
                      onRetry: () => context.read<RecordDetailBloc>().add(
                        LoadRecordDetail(ticketId),
                      ),
                      icon: Icons.cloud_off_outlined,
                    );
                  }
                  final detail = state.detail;
                  return detail == null
                      ? const RecordsNotice(message: 'Ticket not found.')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            VendorRecordDetailContent(detail: detail),
                            const VendorSettlementSection(),
                          ],
                        );
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
