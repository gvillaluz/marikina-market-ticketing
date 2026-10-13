import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/features/tickets/presentation/widgets/evidence_gallery_screen.dart';

void main() {
  testWidgets('editing gallery deletes the current evidence', (tester) async {
    int? deletedIndex;
    final image = MemoryImage(
      Uint8List.fromList(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/G0sAAAAASUVORK5CYII=',
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => EvidenceGalleryScreen(
                    imageProviders: [image],
                    isEditing: true,
                    onDelete: (index) => deletedIndex = index,
                  ),
                ),
              ),
              child: const Text('Open gallery'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open gallery'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Image 1 of 1'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump(const Duration(milliseconds: 400));

    expect(deletedIndex, 0);
    expect(find.text('Open gallery'), findsOneWidget);
  });

  testWidgets('read-only gallery does not allow deleting evidence', (
    tester,
  ) async {
    final image = MemoryImage(
      Uint8List.fromList(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/G0sAAAAASUVORK5CYII=',
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EvidenceGalleryScreen(
          imageProviders: [image],
          isEditing: false,
          onDelete: (_) => fail('read-only gallery must not delete images'),
        ),
      ),
    );
    await tester.pump();

    final deleteButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.delete_outline),
        matching: find.byType(IconButton),
      ),
    );
    expect(deleteButton.onPressed, isNull);
  });
}
