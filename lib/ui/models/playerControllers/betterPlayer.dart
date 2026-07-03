import 'package:kumaanime/core/commons/extractQuality.dart';
import 'package:kumaanime/ui/models/playerControllers/videoController.dart';
import 'package:kumaanime/ui/models/widgets/player/playerUtils.dart';
import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';

class BetterPlayerWrapper implements VideoController {
  late BetterPlayerController controller = BetterPlayerController(_config);

  final List<VoidCallback?> listeners = [];

  final key = GlobalKey();

  static final _config = BetterPlayerConfiguration(
    aspectRatio: 16 / 9,
    fit: BoxFit.contain,
    expandToFill: true,
    autoPlay: true,
    errorBuilder: (context, errorMessage) {
      return Center(
          child: Text(
        "Whoops! Ran into some errors playing this video!\nDetails:\n$errorMessage",
        style: TextStyle(fontSize: 20),
      ));
    },
    eventListener: (ev) {
      if (ev.betterPlayerEventType == BetterPlayerEventType.exception) {
        print("[PLAYER] Oooooooh! We've got some issues!!! \n$ev.parameters");
      }
    },
    autoDispose: true,
    controlsConfiguration: BetterPlayerControlsConfiguration(
      showControls: false,
    ),
  );

  @override
  Future<void> initiateVideo(String url, {Map<String, String>? headers, bool offline = false}) async {
    final mergedHeaders = offline
        ? null
        : <String, String>{
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36',
            ...?headers,
          };
    final ds = offline ? BetterPlayerDataSource.file(url) : await dataSourceConfig(url, headers: mergedHeaders);
    await controller.setupDataSource(ds);
  }

  @override
  bool? get isBuffering {
    try {
      if (!(controller.isVideoInitialized() ?? false)) return false;
      return controller.isBuffering();
    } catch (_) {
      return false;
    }
  }

  @override
  bool? get isPlaying {
    try {
      if (!(controller.isVideoInitialized() ?? false)) return false;
      return controller.isPlaying();
    } catch (_) {
      return false;
    }
  }

  @override
  int? get position => controller.videoPlayerController?.value.position.inMilliseconds;

  @override
  int? get duration => controller.videoPlayerController?.value.duration?.inMilliseconds;

  @override
  int? get buffered => controller.videoPlayerController?.value.buffered.lastOrNull?.end.inSeconds;

  @override
  double? get volume => controller.videoPlayerController?.value.volume;

  @override
  String? get activeMediaUrl => controller.betterPlayerDataSource?.url;

  @override
  bool? get isInitialized => controller.isVideoInitialized();

  @override
  Future<void> pause() {
    return controller.pause();
  }

  @override
  Future<void> play() {
    return controller.play();
  }

  @override
  Future<void> seekTo(Duration duration) {
    return controller.seekTo(duration);
  }

  @override
  Future<void> setSpeed(double speed) async {
    controller.setSpeed(speed);
  }

  @override
  void dispose() {
    for (final cb in listeners) {
      if (cb != null) controller.videoPlayerController?.removeListener(cb);
    }
    listeners.clear();
    final old = controller;
    Future(() => old.dispose());
  }

  @override
  Widget getWidget() {
    return BetterPlayer(controller: controller, key: key);
  }

  @override
  void addListener(VoidCallback cb) {
    listeners.add(cb);
    controller.videoPlayerController?.addListener(cb);
  }

  @override
  void setFit(BoxFit fit) {
    return controller.setOverriddenFit(fit);
  }

  @override
  Future<void> setVolume(double volume) {
    return controller.setVolume(volume);
  }

  @override
  void removeListener(VoidCallback cb) {
    return controller.videoPlayerController?.removeListener(cb);
  }

  @override
  Future<void> setPip(bool value) async {
    if (value)
      controller.enablePictureInPicture(key);
    else
      controller.disablePictureInPicture();
  }

  @override
  Future<void> setAudioTrack(AudioStream aud) async {
    final toLang = _asToAsmsAudioTrack(aud);
    print("Setting to ${toLang.language}, ${toLang.id}");
    return controller.setAudioTrack(toLang);
  }

  @override
  void setQuality(QualityStream qs) async {
    final track = _qsToAsmsTrack(qs);
    if (track == null) {
      return print("[ERROR] No matching track found for '${qs.resolution}', cannot set quality.");
    }

    print("Found matching track: $track");
    return controller.setTrack(track);
  }

  BetterPlayerAsmsTrack? _qsToAsmsTrack(QualityStream qs) {
    try {
      return controller.betterPlayerAsmsTracks.firstWhere((element) {
        final resMatch = element.height == (int.tryParse(qs.resolution.split("x").last) ?? 0);
        final bwMatch = element.bitrate == (qs.bandwidth ?? 0);
        return resMatch && bwMatch;
      }, orElse: () {
        print("[ERROR] No matching track found for '${qs.resolution}', defaulting to first track.");
        return controller.betterPlayerAsmsTracks.first;
      });
    } catch (err) {
      return null;
    }
    // return BetterPlayerAsmsTrack('', int.tryParse(qs.resolution.split("x").first) ?? 0,
    //     int.tryParse(qs.resolution.split("x").last) ?? 0, qs.bandwidth ?? 0, 0, '', '');
  }

  BetterPlayerAsmsAudioTrack _asToAsmsAudioTrack(AudioStream aud) {
    print(controller.betterPlayerAsmsAudioTrack?.language);
    return controller.betterPlayerAsmsAudioTracks!.firstWhere((element) => element.language == aud.language);
  }
}
