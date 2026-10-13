import 'package:flutter/material.dart';
import 'package:marikina_market_mobile/core/theme/app_theme.dart';

class RecordEvidenceViewer extends StatelessWidget {
  final String url;
  final String title;
  const RecordEvidenceViewer({
    required this.url,
    this.title = 'Photo evidence',
    super.key,
  });
  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    child: Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) => const Padding(
              padding: AppTheme.recordsPagePadding,
              child: Text(
                'Photo unavailable. Reopen this record to request a new evidence link.',
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
