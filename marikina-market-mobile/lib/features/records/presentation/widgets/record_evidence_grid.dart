import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'record_evidence_viewer.dart';

class RecordEvidenceGrid extends StatelessWidget {
  final List<String> urls;
  const RecordEvidenceGrid({required this.urls, super.key});
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
    itemBuilder: (context, index) => Semantics(
      label: 'Open evidence photo ${index + 1}',
      button: true,
      child: Material(
        clipBehavior: Clip.antiAlias,
        borderRadius: AppTheme.ticketCardRadius,
        child: InkWell(
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => RecordEvidenceViewer(url: urls[index]),
          ),
          child: Image.network(
            urls[index],
            fit: BoxFit.cover,
            cacheWidth: AppTheme.evidenceDecodeMaxWidth,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : Center(
                    child: SizedBox.square(
                      dimension: AppTheme.buttonIconSize,
                      child: CircularProgressIndicator(
                        value: MediaQuery.disableAnimationsOf(context)
                            ? 0.75
                            : null,
                      ),
                    ),
                  ),
            errorBuilder: (context, error, stack) =>
                const Center(child: Icon(Icons.broken_image_outlined)),
          ),
        ),
      ),
    ),
  );
}
