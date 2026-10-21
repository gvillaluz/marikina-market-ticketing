import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class VendorQrBackground extends StatelessWidget {
  final Widget child;

  const VendorQrBackground({required this.child, super.key});

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppTheme.profileHeroColor,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: -width / 3,
              top: -width / 4,
              width: width * .9,
              height: width * .9,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.profileQrTopCircleOverlay,
                ),
              ),
            ),
            Positioned(
              right: -width * .2,
              bottom: constraints.maxHeight * .04,
              width: width * .7,
              height: width * .7,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.profileQrBottomCircleOverlay,
                ),
              ),
            ),
            child,
          ],
        );
      },
    ),
  );
}
