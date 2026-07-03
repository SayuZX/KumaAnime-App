import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'package:kumaanime/core/commons/enums/hiveEnums.dart';

/// Last unfinished watch session powering the mini resume player.
class ResumeSession {
  static const _key = 'resumeSession';

  static final ValueNotifier<Map<String, dynamic>?> notifier = ValueNotifier(null);

  static Future<void> load() async {
    final box = await Hive.openBox(HiveBox.kumaanime.boxName);
    final raw = box.get(_key);
    notifier.value = raw == null ? null : Map<String, dynamic>.from(raw);
  }

  static Future<void> save(Map<String, dynamic> session) async {
    final box = await Hive.openBox(HiveBox.kumaanime.boxName);
    await box.put(_key, session);
    notifier.value = session;
  }

  static Future<void> clear() async {
    final box = await Hive.openBox(HiveBox.kumaanime.boxName);
    await box.delete(_key);
    notifier.value = null;
  }
}
