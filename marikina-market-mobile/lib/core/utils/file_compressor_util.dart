import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';

Future<File> compressImage(File image) async {
  final targetPath =
      '${image.parent.path}/compressed_${image.uri.pathSegments.last}';

  final result = await FlutterImageCompress.compressAndGetFile(
    image.absolute.path,
    targetPath,
    quality: 80,
    format: CompressFormat.jpeg,
  );

  if (result == null) {
    return image;
  }

  return File(result.path);
}
