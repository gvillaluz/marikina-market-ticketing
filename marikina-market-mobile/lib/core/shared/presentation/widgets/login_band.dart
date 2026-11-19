import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

/// The navy band across the top of every login screen: the city seal, the
/// system name and the headline, with a faint seal in the corner. [opening]
/// runs from 0 to 1 while the seal, the name and then the headline fade in.
class LoginBand extends StatelessWidget {
  final Animation<double> opening;
  const LoginBand({required this.opening, super.key});

  static const _seal = 'assets/logo/org_logo.png';

  Widget _fadeIn(Interval interval, Widget child) => FadeTransition(
    alwaysIncludeSemantics: true,
    opacity: opening.drive(CurveTween(curve: interval)),
    child: child,
  );

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: AppTheme.authBandColor,
    child: Stack(
      children: [
        const Positioned(
          right: AppTheme.authWatermarkRight,
          bottom: AppTheme.authWatermarkBottom,
          child: Image(
            image: AssetImage(_seal),
            width: AppTheme.authWatermarkSize,
            height: AppTheme.authWatermarkSize,
            opacity: AlwaysStoppedAnimation(AppTheme.authWatermarkOpacity),
            excludeFromSemantics: true,
          ),
        ),
        SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppTheme.authMaxWidth,
              ),
              child: Padding(
                padding: AppTheme.authBandPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _fadeIn(
                          AppTheme.authOpeningLogoInterval,
                          Container(
                            width: AppTheme.authSealSize,
                            height: AppTheme.authSealSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.authSealRingColor,
                                width: AppTheme.authSealRingWidth,
                              ),
                            ),
                            child: Image.asset(
                              _seal,
                              excludeFromSemantics: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.authBandBrandGap),
                        Expanded(
                          child: _fadeIn(
                            AppTheme.authOpeningTitleInterval,
                            Semantics(
                              header: true,
                              label: 'Marikina Public Market Inspection System',
                              excludeSemantics: true,
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Marikina Public Market',
                                    style: AppTheme.authBandNameStyle,
                                  ),
                                  Text(
                                    'Inspection System',
                                    style: AppTheme.authBandSystemStyle,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.authBandGap),
                    _fadeIn(
                      AppTheme.authOpeningHeadlineInterval,
                      const Text(
                        'For recording market inspections and tickets.',
                        style: AppTheme.authBandHeadlineStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
