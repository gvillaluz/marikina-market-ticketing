import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class EditAppbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onPressed;

  const EditAppbar({super.key, required this.title, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onPressed,
      ),
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.grey.shade100,

      iconTheme: const IconThemeData(color: AppColors.primary),

      titleTextStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: AppTheme.sectionHeadingFontSize,
        color: AppColors.primary,
      ),
      title: Text(title),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
