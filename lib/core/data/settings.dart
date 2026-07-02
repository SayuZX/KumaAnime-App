import 'package:kumaanime/core/app/logging.dart';
import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/commons/enums/hiveEnums.dart';
import 'package:kumaanime/core/data/types.dart';
import 'package:hive/hive.dart';

class Settings {
  static final String _boxName = HiveBox.kumaanime.boxName;

  Future<SettingsModal> getSettings({bool writing = false}) async {
    var box = await Hive.openBox(_boxName);
    if (!box.isOpen) box = await Hive.openBox(_boxName);
    Map<dynamic, dynamic> settings = await box.get(HiveKey.settings.name) ?? {};
    if (settings.isEmpty) settings = SettingsModal().toMap();
    final classed = SettingsModal.fromMap(settings);
    if (!writing) await box.close();
    return classed;
  }

  Future<void> writeSettings(SettingsModal settings) async {
    var box = await Hive.openBox(_boxName);
    if (!box.isOpen) box = await Hive.openBox(_boxName);
    var currentSettings = (await getSettings(writing: true)).toMap();
    var updatedSettings = settings.toMap();
    Logs.app.log("before updation: $currentSettings");
    Logs.app.log("value upation: $updatedSettings");
    currentSettings.forEach((key, value) {
      if (updatedSettings[key] != null) {
        currentSettings[key] = updatedSettings[key];
      }
    });
    currentUserSettings = SettingsModal.fromMap(currentSettings);
    await box.put(HiveKey.settings.name, currentSettings);
    if (box.isOpen) await box.close;
  }

  Future<void> resetToDefaults() async {
    var box = await Hive.openBox(_boxName);
    if (!box.isOpen) box = await Hive.openBox(_boxName);
    final defaults = SettingsModal.fromMap({}).toMap();
    currentUserSettings = SettingsModal.fromMap(defaults);
    await box.put(HiveKey.settings.name, defaults);
    if (box.isOpen) await box.close();
  }

  Future<void> resetKeys(List<String> keys) async {
    var box = await Hive.openBox(_boxName);
    if (!box.isOpen) box = await Hive.openBox(_boxName);
    final defaults = SettingsModal.fromMap({}).toMap();
    final current = (await getSettings(writing: true)).toMap();
    for (final key in keys) {
      if (defaults.containsKey(key)) current[key] = defaults[key];
    }
    currentUserSettings = SettingsModal.fromMap(current);
    await box.put(HiveKey.settings.name, current);
    if (box.isOpen) await box.close();
  }
}
