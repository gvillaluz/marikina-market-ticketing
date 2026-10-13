import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';
import 'record_evidence_viewer.dart';

class VendorSettlementPhoto extends StatelessWidget {
  final String url, title;
  final double height;
  const VendorSettlementPhoto({
    required this.url,
    required this.title,
    this.height = AppTheme.settlementImageHeight,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url);
    final valid =
        uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
    if (!valid) return const Text('Proof photo unavailable.');
    return Padding(
      padding: AppTheme.selectionSheetItemPadding,
      child: Material(
        clipBehavior: Clip.antiAlias,
        borderRadius: AppTheme.controlRadius,
        child: InkWell(
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => RecordEvidenceViewer(url: url, title: title),
          ),
          child: Image.network(
            url,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            cacheWidth: AppTheme.evidenceDecodeMaxWidth,
            errorBuilder: (context, error, stack) => SizedBox(
              height: height,
              child: Center(
                child: Text(
                  'Proof photo unavailable. Reopen this ticket to try again.',
                ),
              ),
            ),
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : SizedBox(
                    height: height,
                    child: Center(
                      child: SizedBox.square(
                        dimension: AppTheme.buttonIconSize,
                        child: CircularProgressIndicator(
                          value: MediaQuery.disableAnimationsOf(context)
                              ? 0.75
                              : null,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
