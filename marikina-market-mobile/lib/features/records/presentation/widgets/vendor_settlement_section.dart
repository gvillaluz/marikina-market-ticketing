import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import '../../domain/enums/records_filter.dart';
import '../bloc/vendor_settlement/vendor_settlement_bloc.dart';
import '../bloc/vendor_settlement/vendor_settlement_state.dart';
import '../bloc/vendor_settlement/load_vendor_settlement.dart';
import 'records_notice.dart';
import 'vendor_receipt_section.dart';
import 'vendor_service_progress_section.dart';

class VendorSettlementSection extends StatelessWidget {
  const VendorSettlementSection({super.key});
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<VendorSettlementBloc, VendorSettlementState>(
    builder: (context, state) {
      final detail = state.detail;
      if (detail == null || detail.type == RecordsFilter.warning) {
        return const SizedBox.shrink();
      }
      final colors = Theme.of(context).colorScheme;
      return Padding(
        padding: const EdgeInsets.only(top: AppTheme.ticketSmallGap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              state.isService ? 'Community Service Log' : 'Settlement Receipt',
              style: AppTheme.detailTitleStyle.copyWith(color: colors.primary),
            ),
            Text(
              state.isService
                  ? 'Track hours rendered for community service against the required hours on this ticket.'
                  : detail.penaltyType == 'BloodDonation'
                  ? 'Upload a photo of the official donation receipt for this ticket.'
                  : 'Upload a photo of the official payment receipt to complete this ticket’s settlement record.',
            ),
            const SizedBox(height: 10),
            DecoratedBox(
              decoration: AppTheme.ticketSettlementDecoration,
              child: Padding(
                padding: AppTheme.ticketSettlementPadding,
                child: state.isLoading
                    ? Center(
                        child: SizedBox.square(
                          dimension: AppTheme.inspectionProcessingSize,
                          child: CircularProgressIndicator(
                            value: MediaQuery.disableAnimationsOf(context)
                                ? 0.75
                                : null,
                            semanticsLabel: 'Loading settlement details',
                          ),
                        ),
                      )
                    : !state.isLoaded
                    ? RecordsNotice(
                        message:
                            state.error ??
                            'Settlement details are unavailable.',
                        onRetry: () => context.read<VendorSettlementBloc>().add(
                          LoadVendorSettlement(detail),
                        ),
                      )
                    : state.isService && state.progress != null
                    ? VendorServiceProgressSection(progress: state.progress!)
                    : VendorReceiptSection(settlement: state),
              ),
            ),
          ],
        ),
      );
    },
  );
}
