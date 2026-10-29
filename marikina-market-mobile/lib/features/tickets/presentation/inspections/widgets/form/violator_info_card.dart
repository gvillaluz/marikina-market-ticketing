import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/di/dependency_injection.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/vendor_summary.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/auto_fill_btn.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/qr_scanner_screen.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/bottom_sheets/search_by_stall_bottom_sheet.dart';

class ViolatorInfoCard extends StatelessWidget {
  // final TextEditingController stallNumberController;
  // final TextEditingController tradeNameController;
  // final TextEditingController lastNameController;
  // final TextEditingController firstNameController;
  // final TextEditingController middleNameController;
  final ValueChanged<VendorSummary> onVendorSelected;
  final String? errorMessage;

  const ViolatorInfoCard({
    // required this.stallNumberController,
    // required this.tradeNameController,
    // required this.lastNameController,
    // required this.firstNameController,
    // required this.middleNameController,
    required this.onVendorSelected,
    required this.errorMessage,
    super.key,
  });

  Future<void> _handleQrScan(BuildContext context) async {
    final vendor = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (_) => sl<InspectionBloc>(),
          child: const QrScannerScreen(),
        ),
      ),
    );

    if (vendor == null) return;

    onVendorSelected(vendor);
  }

  Future<void> _handleSearchById(BuildContext context) async {
    final selectedVendor = await showModalBottomSheet<VendorSummary>(
      context: context,
      enableDrag: true,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : const AnimationStyle(
              duration: AppTheme.pageTransitionDuration,
              reverseDuration: AppTheme.pageReverseTransitionDuration,
            ),
      builder: (context) => BlocProvider(
        create: (_) => sl<InspectionBloc>(),
        child: SearchByBusinessAccountNumberBottomSheet(),
      ),
    );

    if (selectedVendor == null) return;

    onVendorSelected(selectedVendor);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.tertiary,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Icon(Icons.search, color: AppColors.primary, size: 40),
        ),

        const SizedBox(height: 10),

        const Text(
          'Find Vendor',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: AppTheme.sectionHeadingFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Scan QR code or search vendor by stall number to begin inspection',
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 20),

        Row(
          spacing: 10,
          children: [
            AutoFillBtn(
              label: 'Scan QR Code',
              icon: Icons.qr_code_scanner,
              onPressed: () => _handleQrScan(context),
            ),
            AutoFillBtn(
              label: 'Search by ID',
              icon: Icons.search,
              onPressed: () => _handleSearchById(context),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Row(
        //   spacing: 10,
        //   children: [
        //     Expanded(
        //       child: const Divider(
        //         height: 1,
        //       ),
        //     ),
        //     const Text(
        //       'or fill manually',
        //       style: TextStyle(
        //         color: AppColors.mediumGrey
        //       ),
        //     ),
        //     Expanded(
        //       child: const Divider(
        //         height: 1,
        //       ),
        //     )
        //   ],
        // ),
        const Divider(),

        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppColors.tertiary.withValues(alpha: .60),
          ),
          child: const ListTile(
            leading: Icon(Icons.info_outline_rounded, color: AppColors.primary),
            title: Text(
              'Vendor information is required',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            subtitle: Text(
              'Please find the vendor to view details and create a record.',
            ),
          ),
        ),

        // if (errorMessage != null) ...[
        //   ErrorBanner(
        //     message: 'Please select a registered vendor or enter stall info.'
        //   ),

        //   const SizedBox(height: 20,),
        // ],

        // ViolatorInfoFields(
        //   stallNumberController: stallNumberController,
        //   tradeNameController: tradeNameController,
        //   lastNameController: lastNameController,
        //   firstNameController: firstNameController,
        //   middleNameController: middleNameController
        // ),
      ],
    );
  }
}
