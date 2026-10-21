import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class InspectionEvidenceTile extends StatelessWidget {
  final XFile photo;
  final int index;
  final VoidCallback onOpen;
  final VoidCallback? onDelete;
  const InspectionEvidenceTile({
    required this.photo,
    required this.index,
    required this.onOpen,
    this.onDelete,
    super.key,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final pixels =
          (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
              .ceil()
              .clamp(1, AppTheme.evidenceDecodeMaxWidth)
              .toInt();
      return Stack(
        fit: StackFit.expand,
        children: [
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: AppTheme.inspectionCardRadius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onOpen,
              child: Semantics(
                label: 'Open evidence photo ${index + 1}',
                button: true,
                child: Hero(
                  tag: FileImage(File(photo.path)),
                  child: Image.file(
                    File(photo.path),
                    fit: BoxFit.cover,
                    cacheWidth: pixels,
                    errorBuilder: (context, error, stack) => Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        semanticLabel: 'Photo unavailable',
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (onDelete != null)
            Positioned(
              top: AppTheme.inspectionTinyGap,
              right: AppTheme.inspectionTinyGap,
              child: IconButton.filledTonal(
                tooltip: 'Remove photo ${index + 1}',
                onPressed: onDelete,
                constraints: BoxConstraints(
                  minWidth: AppTheme.buttonMinSize.width,
                  minHeight: AppTheme.buttonMinSize.width,
                ),
                icon: const Icon(Icons.close, size: AppTheme.buttonIconSize),
              ),
            ),
        ],
      );
    },
  );
}
