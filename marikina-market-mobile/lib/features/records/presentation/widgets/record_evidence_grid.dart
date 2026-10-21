import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'record_evidence_viewer.dart';

class RecordEvidenceGrid extends StatelessWidget {
  final List<String> urls;
  const RecordEvidenceGrid({required this.urls, super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = (constraints.maxWidth - AppTheme.inspectionSmallGap) / 2;
      return Wrap(
        spacing: AppTheme.inspectionSmallGap,
        runSpacing: AppTheme.inspectionSmallGap,
        children: [
          for (var index = 0; index < urls.length; index++)
            SizedBox(
              width: width,
              child: Material(
                clipBehavior: Clip.antiAlias,
                borderRadius: AppTheme.controlRadius,
                child: InkWell(
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (_) => RecordEvidenceViewer(url: urls[index]),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AspectRatio(
                        aspectRatio: AppTheme.evidenceTileAspectRatio,
                        child: Image.network(
                          urls[index],
                          fit: BoxFit.cover,
                          cacheWidth: AppTheme.evidenceDecodeMaxWidth,
                          loadingBuilder: (context, child, progress) =>
                              progress == null
                              ? child
                              : Center(
                                  child: SizedBox.square(
                                    dimension: AppTheme.buttonIconSize,
                                    child: CircularProgressIndicator(
                                      value:
                                          MediaQuery.disableAnimationsOf(
                                            context,
                                          )
                                          ? 0.75
                                          : null,
                                    ),
                                  ),
                                ),
                          errorBuilder: (context, error, stack) => const Center(
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                      Text(
                        'Photo ${index + 1}',
                        style: AppTheme.recordsCaptionStyle,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
