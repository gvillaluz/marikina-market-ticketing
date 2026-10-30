import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/evidence_gallery_screen.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_evidence.dart';

class TicketDetailEvidenceSection extends StatelessWidget {
  final List<String> evidences;
  final bool isTicket;
  final List<TicketEvidence> evidenceItems;
  const TicketDetailEvidenceSection({
    required this.evidences,
    required this.isTicket,
    this.evidenceItems = const [],
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    if (!isTicket) return _buildPhotos(context);
    final groups = <String, List<String>>{};
    if (evidenceItems.isEmpty) {
      groups['Unclassified evidence'] = evidences;
    } else {
      for (final role in ['PaperTicket', 'Supporting', null]) {
        final items =
            evidenceItems
                .where(
                  (item) => role == null
                      ? item.role != 'PaperTicket' && item.role != 'Supporting'
                      : item.role == role,
                )
                .toList()
              ..sort((a, b) {
                final order = (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0);
                return order == 0 ? a.id.compareTo(b.id) : order;
              });
        if (items.isNotEmpty) {
          groups[role == 'PaperTicket'
              ? 'Paper ticket photo'
              : role == 'Supporting'
              ? 'Supporting evidence'
              : 'Unclassified evidence'] = items
              .map((item) => item.url)
              .toList();
        }
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in groups.entries) ...[
          Text(group.key, style: AppTheme.inspectionBodyStyle),
          const SizedBox(height: AppTheme.ticketSmallGap),
          TicketDetailEvidenceSection(evidences: group.value, isTicket: false),
          const SizedBox(height: AppTheme.ticketSmallGap),
        ],
      ],
    );
  }

  Widget _buildPhotos(BuildContext context) => Container(
    padding: AppTheme.ticketCardPadding,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: AppTheme.ticketCardRadius,
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: AppTheme.evidenceTileMaxWidth,
        crossAxisSpacing: AppTheme.ticketSmallGap,
        mainAxisSpacing: AppTheme.ticketSmallGap,
        childAspectRatio: AppTheme.evidenceTileAspectRatio,
      ),
      itemCount: evidences.length,
      itemBuilder: (context, index) => LayoutBuilder(
        builder: (context, constraints) {
          final pixels =
              (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                  .ceil()
                  .clamp(1, AppTheme.evidenceDecodeMaxWidth)
                  .toInt();
          return Material(
            borderRadius: AppTheme.ticketCardRadius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => EvidenceGalleryScreen(
                    imageProviders: evidences
                        .map((url) => CachedNetworkImageProvider(url))
                        .toList(),
                    initialIndex: index,
                    isEditing: false,
                  ),
                ),
              ),
              child: Semantics(
                label: 'Open evidence photo ${index + 1}',
                button: true,
                child: Hero(
                  tag: CachedNetworkImageProvider(evidences[index]),
                  child: CachedNetworkImage(
                    imageUrl: evidences[index],
                    memCacheWidth: pixels,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: SizedBox.square(
                        dimension: AppTheme.buttonIconSize,
                        child: CircularProgressIndicator(
                          value: MediaQuery.disableAnimationsOf(context)
                              ? 0.75
                              : null,
                          strokeWidth: AppTheme.buttonProgressStrokeWidth,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.broken_image_outlined,
                      semanticLabel: 'Photo unavailable',
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
