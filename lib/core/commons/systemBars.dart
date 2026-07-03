import 'dart:io';

import 'package:flutter/services.dart';

const _channel = MethodChannel('kumaanime.app/utils');

/// Forces the Android system bars visible through the native window controller.
Future<void> showSystemBars() async {
  if (!Platform.isAndroid) return;
  try {
    await _channel.invokeMethod('showSystemBars');
  } catch (_) {}
}

/// Hides the Android system bars for immersive playback.
Future<void> hideSystemBars() async {
  if (!Platform.isAndroid) return;
  try {
    await _channel.invokeMethod('hideSystemBars');
  } catch (_) {}
}
