import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersion {
  /// App's version
  late final String version;
  late final String buildNumber;
  late final String buildDate;

  AppVersion._();

  static AppVersion? _instance;

  static AppVersion get instance {
    if (_instance != null) {
      return _instance!;
    } else {
      throw Exception("AppVersion has not yet been initialised.");
    }
  }

  /// Initialises the instance, Loads version
  static Future<void> init() async {
    final info = await PackageInfo.fromPlatform();
    final instance = AppVersion._();
    instance.version = info.version;
    instance.buildNumber = info.buildNumber;
    instance.buildDate = _formatBuildDate(info.buildNumber);
    _instance = instance;
  }

  static String _formatBuildDate(String buildNum) {
    if (buildNum.length >= 8 && RegExp(r'^\d{8}').hasMatch(buildNum)) {
      final s = buildNum.substring(0, 8);
      return "${s.substring(0, 4)}-${s.substring(4, 6)}-${s.substring(6, 8)}";
    }
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  /// Codename
  final String nickname = 'Moonrise';

  /// Color code
  final colorCode = [Color.fromARGB(255, 60, 66, 87), Color.fromARGB(255, 78, 64, 85)];
}