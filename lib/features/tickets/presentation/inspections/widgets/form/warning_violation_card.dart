import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/shared/presentation/widgets/app_primary_btn.dart';

class WarningViolationCard extends StatelessWidget {
  final TextEditingController placeOfApprehensionController;
  final TextEditingController descriptionController;
  final ValueChanged<BuildContext> onPressed;

  const WarningViolationCard({
    super.key,
    required this.placeOfApprehensionController,
    required this.descriptionController,
    required this.onPressed
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.primaryLight,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.50),
              offset: const Offset(-0.5, 0.5),
              blurRadius: 4,
              spreadRadius: -1,
            )
          ]
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VIOLATION',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 20
            ),
          ),

          const Divider(height: 20,),

          const Text(
            'ORDINANCE',
          ),
          const SizedBox(height: 5,),
          AppPrimaryButton(
            label: 'Select Ordinance', 
            iconData: Icons.add_circle, 
            onPressed: () => onPressed(context)
          ),

          const SizedBox(height: 20,),

          const Text(
            'PLACE OF APPREHENSION'
          ),
          const SizedBox(height: 5,),
          TextField(
            controller: placeOfApprehensionController,
          ),

          const SizedBox(height: 20,),

          const Text(
            'DESCRIPTION'
          ),
          const SizedBox(height: 5,),
          TextField(
            controller: descriptionController,
            maxLines: 5,
            minLines: 3,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
          )
        ],
      ),
    );
  }
}