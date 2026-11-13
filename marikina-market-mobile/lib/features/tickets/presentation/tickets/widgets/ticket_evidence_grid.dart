import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_evidence_photo.dart';

// Evidence photos as small tiles that wrap to the screen width.
class TicketEvidenceGrid extends StatelessWidget {
  final List<String> urls;
  const TicketEvidenceGrid({required this.urls, super.key});

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: AppTheme.evidenceTileMaxWidth,
      crossAxisSpacing: AppTheme.ticketSmallGap,
      mainAxisSpacing: AppTheme.ticketSmallGap,
      childAspectRatio: AppTheme.evidenceTileAspectRatio,
    ),
    itemCount: urls.length,
    itemBuilder: (context, index) =>
        TicketEvidencePhoto(urls: urls, index: index),
  );
}
