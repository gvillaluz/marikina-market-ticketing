import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/inspections/widgets/inspection_evidence_tile.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/evidence_gallery_screen.dart';

class InspectionEvidenceGrid extends StatelessWidget {
  final List<XFile> photos;
  final ValueChanged<int>? onDelete;
  const InspectionEvidenceGrid({
    required this.photos,
    this.onDelete,
    super.key,
  });
  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: AppTheme.evidenceTileMaxWidth,
      crossAxisSpacing: AppTheme.inspectionSmallGap,
      mainAxisSpacing: AppTheme.inspectionSmallGap,
      childAspectRatio: AppTheme.evidenceTileAspectRatio,
    ),
    itemCount: photos.length,
    itemBuilder: (context, index) => InspectionEvidenceTile(
      key: ValueKey(photos[index].path),
      photo: photos[index],
      index: index,
      onDelete: onDelete == null ? null : () => onDelete!(index),
      onOpen: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EvidenceGalleryScreen(
            imageProviders: photos
                .map((photo) => FileImage(File(photo.path)))
                .toList(),
            initialIndex: index,
            isEditing: onDelete != null,
            onDelete: onDelete,
          ),
        ),
      ),
    ),
  );
}
