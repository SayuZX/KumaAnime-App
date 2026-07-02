import 'package:hive/hive.dart';
import 'package:kumaanime/core/commons/enums/hiveEnums.dart';

class SubIndoWatched {
  static final String _boxName = HiveBox.kumaanime.boxName;
  static const String _key = 'subIndoWatched';

  static Set<int> _parseList(dynamic raw) {
    if (raw is! List) return {};
    return raw.map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).toSet();
  }

  static Future<Box> _box() async {
    return Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : await Hive.openBox(_boxName);
  }

  static Future<Set<int>> getWatched(String animeId) async {
    final box = await _box();
    final all = Map.from(box.get(_key) ?? {});
    final entry = all[animeId];
    return _parseList(entry is Map ? entry['watched'] : null);
  }

  static Future<int?> getLast(String animeId) async {
    final box = await _box();
    final all = Map.from(box.get(_key) ?? {});
    final entry = all[animeId];
    final last = entry is Map ? entry['last'] : null;
    if (last is int) return last;
    return last != null ? int.tryParse(last.toString()) : null;
  }

  static Future<void> mark(String animeId, int episodeNumber) async {
    final box = await _box();
    final all = Map.from(box.get(_key) ?? {});
    final entry = Map.from(all[animeId] ?? {});
    final watched = _parseList(entry['watched'])..add(episodeNumber);
    entry['watched'] = watched.toList()..sort();
    entry['last'] = episodeNumber;
    all[animeId] = entry;
    await box.put(_key, all);
  }

  static Future<void> markAll(String animeId, List<int> episodeNumbers) async {
    if (episodeNumbers.isEmpty) return;
    final box = await _box();
    final all = Map.from(box.get(_key) ?? {});
    final entry = Map.from(all[animeId] ?? {});
    entry['watched'] = (episodeNumbers.toSet().toList()..sort());
    entry['last'] = episodeNumbers.reduce((a, b) => a > b ? a : b);
    all[animeId] = entry;
    await box.put(_key, all);
  }

  static Future<void> reset(String animeId) async {
    final box = await _box();
    final all = Map.from(box.get(_key) ?? {});
    all.remove(animeId);
    await box.put(_key, all);
  }
}
