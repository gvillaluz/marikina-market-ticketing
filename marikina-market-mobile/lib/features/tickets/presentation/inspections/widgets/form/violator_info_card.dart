import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/core/di/dependency_injection.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/market_section.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/vendor_summary.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/bloc/inspection_bloc.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/auto_fill_btn.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/bottom_sheets/search_business_bottom_sheet.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/unregistered_section_picker.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/form/vendor_kind_toggle.dart';

class ViolatorInfoCard extends StatelessWidget {
  // final TextEditingController stallNumberController;
  // final TextEditingController tradeNameController;
  // final TextEditingController lastNameController;
  // final TextEditingController firstNameController;
  // final TextEditingController middleNameController;
  final bool isUnregistered;
  final ValueChanged<bool> onKindChanged;
  final ValueChanged<VendorSummary> onVendorSelected;
  final ValueChanged<MarketSection> onSectionSelected;
  final String? errorMessage;

  const ViolatorInfoCard({
    // required this.stallNumberController,
    // required this.tradeNameController,
    // required this.lastNameController,
    // required this.firstNameController,
    // required this.middleNameController,
    required this.isUnregistered,
    required this.onKindChanged,
    required this.onVendorSelected,
    required this.onSectionSelected,
    required this.errorMessage,
    super.key,
  });

  Future<void> _handleBusinessSearch(BuildContext context) async {
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
        child: SearchBusinessBottomSheet(),
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
        Text(
          isUnregistered
              ? 'Choose the market section where the vendor was found'
              : 'Search by business name, stall, owner, address or account number',
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 20),

        VendorKindToggle(
          isUnregistered: isUnregistered,
          onChange: onKindChanged,
        ),

        const SizedBox(height: 20),

        if (isUnregistered)
          UnregisteredSectionPicker(onSelected: onSectionSelected)
        else
          Row(
            children: [
              AutoFillBtn(
                label: 'Search business',
                icon: Icons.search,
                onPressed: () => _handleBusinessSearch(context),
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
          child: ListTile(
            leading: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.primary,
            ),
            title: const Text(
              'Vendor information is required',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            subtitle: Text(
              isUnregistered
                  ? 'Please choose the market section to create a record.'
                  : 'Please find the vendor to view details and create a record.',
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
