import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageCompressor {
  static const int maxBytes = 2 * 1024 * 1024;

  static Future<Uint8List?> compressUnder2MB(String path) async {
    for (final quality in [92, 85, 75, 65, 55, 45]) {
      final data = await FlutterImageCompress.compressWithFile(
        path,
        quality: quality,
        minWidth: 2048,
        minHeight: 2048,
        format: CompressFormat.jpeg,
      );
      if (data != null && data.length <= maxBytes) return data;
    }

    for (final dimension in [1440, 1080, 720]) {
      final data = await FlutterImageCompress.compressWithFile(
        path,
        quality: 60,
        minWidth: dimension,
        minHeight: dimension,
        format: CompressFormat.jpeg,
      );
      if (data != null && data.length <= maxBytes) return data;
    }

    return FlutterImageCompress.compressWithFile(
      path,
      quality: 45,
      minWidth: 512,
      minHeight: 512,
      format: CompressFormat.jpeg,
    );
  }
}
