import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/inspection_evidence_grid.dart';

class PhotoEvidencePreviewSection extends StatelessWidget {
  final List<XFile> evidences;
  const PhotoEvidencePreviewSection({required this.evidences, super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: AppTheme.inspectionCardPadding,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: AppTheme.inspectionCardRadius,
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: InspectionEvidenceGrid(photos: evidences),
  );
}
