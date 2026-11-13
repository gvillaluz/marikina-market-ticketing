import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_evidence_grid.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_evidence_photo.dart';

// A titled box of one kind of ticket photo, with its photo count. The paper
// ticket photos are shown large and whole; other photos sit in a grid.
class TicketEvidenceGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> urls;
  final bool large;
  const TicketEvidenceGroup({
    required this.title,
    required this.icon,
    required this.urls,
    this.large = false,
    super.key,
  });

  static const _largeAspectRatio = 4 / 3;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: AppTheme.ticketCardPadding,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppTheme.ticketCardRadius,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: AppTheme.ticketTinyGap),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.inspectionBodyStyle.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${urls.length} ${urls.length == 1 ? 'photo' : 'photos'}',
                style: AppTheme.inspectionCaptionStyle.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.ticketSmallGap),
          if (large)
            Column(
              spacing: AppTheme.ticketSmallGap,
              children: [
                for (var i = 0; i < urls.length; i++)
                  AspectRatio(
                    aspectRatio: _largeAspectRatio,
                    child: TicketEvidencePhoto(
                      urls: urls,
                      index: i,
                      fit: BoxFit.contain,
                    ),
                  ),
              ],
            )
          else
            TicketEvidenceGrid(urls: urls),
        ],
      ),
    );
  }
}
