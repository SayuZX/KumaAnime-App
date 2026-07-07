import 'package:kumaanime/core/anime/downloader/downloaderHelper.dart';
import 'package:kumaanime/core/anime/downloader/types.dart';
import 'package:kumaanime/core/commons/enums/hiveEnums.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DownloadHistory {
  static final String _boxName = HiveBox.downloadHistory.boxName;

  static Future<void> initBox() => Hive.openBox(_boxName);

  static ValueListenable<Box> get listenable => Hive.box(_boxName).listenable();

  static List<DownloadHistoryItem> getDownloadHistory({DownloadStatus? status = DownloadStatus.completed}) {
    final box = Hive.box(_boxName);
    final filtered = <DownloadHistoryItem>[];
    for (final key in box.keys) {
      try {
        final val = box.get(key);
        if (val != null) {
          final item = DownloadHistoryItem.fromMap(Map.castFrom(val));
          if (status == null || item.status == status) {
            filtered.add(item);
          }
        }
      } catch (_) {}
    }
    return filtered;
  }

  static Future<void> saveItem(DownloadHistoryItem item) async {
    final box = Hive.box(_boxName);
    
    // Write directly using the item's unique id to overwrite/update existing records
    await box.put(item.id, item.toMap());

    // Prune only completed/cancelled history records if the total box size exceeds 200
    if (box.length > 200) {
      final keys = box.keys.toList().cast<int>();
      final completedKeys = <int>[];
      for (final k in keys) {
        final val = box.get(k);
        if (val != null) {
          final statusStr = val['status'];
          if (statusStr == DownloadStatus.completed.name || statusStr == DownloadStatus.cancelled.name) {
            completedKeys.add(k);
          }
        }
      }

      if (completedKeys.length > 100) {
        completedKeys.sort((a, b) {
          final int at = box.get(a)?['timestamp'] ?? 0;
          final int bt = box.get(b)?['timestamp'] ?? 0;
          return at.compareTo(bt);
        });
        final deletable = completedKeys.sublist(100);
        await box.deleteAll(deletable);
      }
    }
  }

  static Future<void> removeItem(int id) async {
    final box = Hive.box(_boxName);
    await box.delete(id);
  }

  static Future<void> clearAll() async {
    final box = Hive.box(_boxName);
    await box.clear();
  }
}
