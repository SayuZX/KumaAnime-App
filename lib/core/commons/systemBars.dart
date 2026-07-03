import 'dart:io';

import 'package:flutter/services.dart';

const _channel = MethodChannel('kumaanime.app/utils');

Future<void> showSystemBars() async {
  if (!Platform.isAndroid) return;
  try {
    await _channel.invokeMethod('showSystemBars');
  } catch (_) {}
}

Future<void> hideSystemBars() async {
  if (!Platform.isAndroid) return;
  try {
    await _channel.invokeMethod('hideSystemBars');
  } catch (_) {}
}

Future<bool> enterPip() async {
  if (!Platform.isAndroid) return false;
  try {
    final ok = await _channel.invokeMethod('enterPip');
    return ok == true;
  } catch (_) {
    return false;
  }
}
