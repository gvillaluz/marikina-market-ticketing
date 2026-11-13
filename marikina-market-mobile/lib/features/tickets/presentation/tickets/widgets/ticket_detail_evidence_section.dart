import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ticket_evidence.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_evidence_grid.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/tickets/widgets/ticket_evidence_group.dart';

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

  List<String> _urlsFor(String? role) {
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
    return items.map((item) => item.url).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!isTicket) return _buildPhotos(context);
    final paper = _urlsFor('PaperTicket');
    final supporting = _urlsFor('Supporting');
    final unclassified = evidenceItems.isEmpty ? evidences : _urlsFor(null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppTheme.ticketSmallGap,
      children: [
        if (paper.isNotEmpty)
          TicketEvidenceGroup(
            title: 'Paper ticket',
            icon: Icons.description_outlined,
            urls: paper,
            large: true,
          ),
        if (supporting.isNotEmpty)
          TicketEvidenceGroup(
            title: 'Supporting evidence',
            icon: Icons.photo_camera_outlined,
            urls: supporting,
          ),
        if (unclassified.isNotEmpty)
          TicketEvidenceGroup(
            title: 'Unclassified evidence',
            icon: Icons.photo_library_outlined,
            urls: unclassified,
          ),
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
    child: TicketEvidenceGrid(urls: evidences),
  );
}
