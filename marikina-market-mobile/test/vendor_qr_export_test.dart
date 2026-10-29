import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/profile/data/data_sources/qr_export_data_source.dart';
import 'package:marikina_market_mobile/features/profile/data/repositories/qr_export_repository_impl.dart';
import 'package:marikina_market_mobile/features/profile/domain/use_cases/export_qr_params.dart';
import 'package:marikina_market_mobile/features/profile/domain/use_cases/export_qr_use_case.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final png = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);
  final useCase = ExportQrUseCase(QrExportRepositoryImpl(QrExportDataSource()));
  tearDown(() {
    for (final name in [
      'file_saver',
      'dev.fluttercommunity.plus/share',
      'plugins.flutter.io/path_provider',
    ]) {
      messenger.setMockMethodCallHandler(MethodChannel(name), null);
    }
  });
  test('save hands PNG bytes to the platform with a safe filename', () async {
    MethodCall? sent;
    messenger.setMockMethodCallHandler(const MethodChannel('file_saver'), (
      call,
    ) async {
      sent = call;
      return Platform.isWindows
          ? Int64List.fromList('saved.png'.codeUnits)
          : 'saved.png';
    });
    final result = await useCase(
      ExportQrParams(
        pngBytes: png,
        businessAccountNumber: 'MM/70',
        share: false,
      ),
    );
    expect(result, isA<Success<bool>>());
    expect((result as Success<bool>).data, isTrue);
    expect(sent?.method, 'saveAs');
    final args = sent!.arguments as Map<Object?, Object?>;
    expect(args['mimeType'], 'image/png');
    expect(args['bytes'], png);
    expect(args['name'], 'vendor-qr-MM_70');
  });
  test('cancelled save is not reported as a successful download', () async {
    messenger.setMockMethodCallHandler(
      const MethodChannel('file_saver'),
      (_) async => null,
    );
    final result = await useCase(
      ExportQrParams(
        pngBytes: png,
        businessAccountNumber: 'MM-70',
        share: false,
      ),
    );
    expect((result as Success<bool>).data, isFalse);
  });
  test('platform export failure becomes a user-facing failure', () async {
    messenger.setMockMethodCallHandler(const MethodChannel('file_saver'), (
      _,
    ) async {
      throw PlatformException(code: 'unavailable');
    });
    final result = await useCase(
      ExportQrParams(
        pngBytes: png,
        businessAccountNumber: 'MM-70',
        share: false,
      ),
    );
    expect(
      (result as ResultFailure<bool>).failure.message,
      'Unable to export your QR code. Please try again.',
    );
  });
  test(
    'sharing passes a PNG file and its anchor to the native share sheet',
    () async {
      MethodCall? sent;
      final temp = Directory(
        'evidence/vendor-profile-cached-ui/share-temp',
      ).absolute;
      await temp.create(recursive: true);
      messenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => temp.path,
      );
      messenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/share'),
        (call) async {
          sent = call;
          final args = call.arguments as Map<Object?, Object?>;
          final paths = args['paths'] as List<Object?>;
          expect(await File(paths.single as String).readAsBytes(), png);
          return 'test.receiver';
        },
      );
      final result = await useCase(
        ExportQrParams(
          pngBytes: png,
          businessAccountNumber: 'MM-70',
          share: true,
          origin: (x: 10, y: 20, width: 100, height: 40),
        ),
      );
      expect(result, isA<Success<bool>>());
      expect((result as Success<bool>).data, isTrue);
      expect(sent?.method, 'share');
      expect((sent!.arguments as Map<Object?, Object?>)['mimeTypes'], [
        'image/png',
      ]);
    },
  );
}
