import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageCompressor {
  static const int maxBytes = 2 * 1024 * 1024;

  static Future<String?> compressToBase64(String path, {int maxBytes = 120000}) async {
    for (final dimension in [512, 384, 256]) {
      for (final quality in [80, 65, 50]) {
        final data = await FlutterImageCompress.compressWithFile(
          path,
          quality: quality,
          minWidth: dimension,
          minHeight: dimension,
          format: CompressFormat.jpeg,
        );
        if (data != null && data.length <= maxBytes) return base64Encode(data);
      }
    }
    final data = await FlutterImageCompress.compressWithFile(
      path,
      quality: 40,
      minWidth: 200,
      minHeight: 200,
      format: CompressFormat.jpeg,
    );
    return data != null ? base64Encode(data) : null;
  }

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
