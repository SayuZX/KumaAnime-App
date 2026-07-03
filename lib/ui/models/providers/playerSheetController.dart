import 'package:flutter/widgets.dart';

import 'package:kumaanime/core/anime/providers/types.dart';
import 'package:kumaanime/core/data/resumeSession.dart';
import 'package:kumaanime/core/database/types.dart';
import 'package:kumaanime/ui/models/playerControllers/videoController.dart';
import 'package:kumaanime/ui/models/providers/playerDataProvider.dart';
import 'package:kumaanime/ui/models/providers/playerProvider.dart';

class PlayerSheet extends ChangeNotifier {
  PlayerSheet._();

  static final PlayerSheet instance = PlayerSheet._();

  VideoController? controller;
  PlayerDataProvider? dataProvider;
  PlayerProvider? playerProvider;

  GlobalKey<NavigatorState> nestedNavKey = GlobalKey<NavigatorState>();

  static final backInterceptor = _SheetBackObserver();

  double visualValue = 1;

  bool _expandRequested = true;

  bool get active => controller != null;

  bool get expandRequested => _expandRequested;

  void open({
    required VideoController videoController,
    required List<VideoStream> streams,
    required VideoStream initialStream,
    required List<EpisodeDetails> epLinks,
    required String title,
    String? cover,
    required int showId,
    required String selectedSource,
    required int startIndex,
    List<AlternateDatabaseId> altDatabases = const [],
    bool preferDubs = false,
    double? lastWatchDuration,
  }) {
    if (active) close();

    nestedNavKey = GlobalKey<NavigatorState>();
    controller = videoController;
    dataProvider = PlayerDataProvider(
      initialStreams: streams,
      initialStream: initialStream,
      epLinks: epLinks,
      showTitle: title,
      coverImageUrl: cover,
      showId: showId,
      selectedSource: selectedSource,
      startIndex: startIndex,
      altDatabases: altDatabases,
      preferDubs: preferDubs,
      lastWatchDuration: lastWatchDuration,
    );
    playerProvider = PlayerProvider(controller!, true);
    _expandRequested = true;
    notifyListeners();
  }

  void requestExpand() {
    _expandRequested = true;
    notifyListeners();
  }

  void requestMinimize() {
    _expandRequested = false;
    notifyListeners();
  }

  Future<void> saveProgress() async {
    final dp = dataProvider;
    final c = controller;
    if (dp == null || c == null) return;
    final dur = (c.duration ?? 0).toDouble();
    if (dur <= 0) return;
    final pos = (c.position ?? 0).toDouble();
    final pct = (pos / dur).clamp(0.0, 1.0);

    if (pct >= 0.9) {
      await ResumeSession.clear();
      return;
    }
    await ResumeSession.save({
      'showId': dp.showId,
      'title': dp.showTitle,
      'cover': dp.coverImageUrl,
      'episodeIndex': dp.state.currentEpIndex,
      'episodeNumber': dp.epLinks[dp.state.currentEpIndex].episodeNumber,
      'progress': pct,
      'positionMs': pos.toInt(),
      'durationMs': dur.toInt(),
      'stream': dp.state.currentStream.toMap(),
      'epLinks': dp.epLinks.map((e) => e.toMap()).toList(),
      'selectedSource': dp.selectedSource,
      'preferDubs': dp.preferDubs,
    });
  }

  Future<void> close({bool save = true}) async {
    if (!active) return;
    if (save) await saveProgress();

    final oldController = controller;
    final oldData = dataProvider;
    final oldPlayer = playerProvider;

    controller = null;
    dataProvider = null;
    playerProvider = null;
    notifyListeners();

    Future(() {
      oldController?.dispose();
      oldData?.dispose();
      oldPlayer?.dispose();
    });
  }
}

class _SheetBackObserver with WidgetsBindingObserver {
  @override
  Future<bool> didPopRoute() async {
    final sheet = PlayerSheet.instance;
    if (!sheet.active) return false;
    if (sheet.visualValue > 0.5) {
      final nav = sheet.nestedNavKey.currentState;
      if (nav != null && nav.canPop()) {
        await nav.maybePop();
      } else {
        sheet.requestMinimize();
      }
      return true;
    }
    return false;
  }
}
