import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/constants/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: AppColors.primary
        ),
        height: double.infinity,
        width: double.infinity,
        child: const Center(
          child: SizedBox(
            child: CircularProgressIndicator(
              color: AppColors.primaryLight,
            ),
          ),
        ),
      ),
    );
  }
}