import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:kumaanime/core/commons/extractQuality.dart';
import 'package:kumaanime/ui/models/playerControllers/videoController.dart';
import 'package:video_player/video_player.dart';

class FvpWrapper implements VideoController {
  VideoPlayerController controller = VideoPlayerController.networkUrl(Uri.parse(""));

  bool controllerInitialized = false;
  final List<VoidCallback> listeners = [];

  double _currentVolume = 1.0;
  bool _isMuted = false;
  String? _activeAudioDevice;
  int _audioSyncDelayMs = 0;

  @override
  String? get activeMediaUrl => controller.dataSource;

  @override
  int? get buffered => controller.value.buffered.lastOrNull?.end.inSeconds;

  @override
  void dispose() {
    final old = controller;
    for (final listener in listeners) {
      old.removeListener(listener);
    }
    listeners.clear();
    Future(() => old.dispose());
  }

  @override
  int? get duration => controller.value.duration.inMilliseconds;

  @override
  Widget getWidget() {
    return AspectRatio(aspectRatio: 16 / 9, child: VideoPlayer(controller));
  }

  void setAudioDevice(String deviceIdOrName) {
    _activeAudioDevice = deviceIdOrName;
    if (controllerInitialized) {
      if (deviceIdOrName == 'default' || deviceIdOrName.isEmpty) {
        controller.setProperty("audio.device", "wasapi");
      } else {
        controller.setProperty("audio.device", deviceIdOrName);
      }
    }
  }

  void setAudioSyncDelay(int delayMs) {
    _audioSyncDelayMs = delayMs;
    if (controllerInitialized) {
      final sec = delayMs / 1000.0;
      controller.setProperty("audio-delay", "$sec");
    }
  }

  void setMute(bool mute) {
    _isMuted = mute;
    if (controllerInitialized) {
      controller.setVolume(mute ? 0.0 : _currentVolume);
    }
  }

  @override
  Future<void> initiateVideo(String url, {Map<String, String>? headers, bool offline = false}) async {
    if (controllerInitialized) {
      final old = controller;
      for (final listener in listeners) {
        old.removeListener(listener);
      }
      Future(() => old.dispose());
      controllerInitialized = false;
    }

    controller = offline
        ? VideoPlayerController.file(File(url))
        : VideoPlayerController.networkUrl(
            Uri.parse(url),
            httpHeaders: headers ?? {},
          );

    controllerInitialized = true;

    await controller.initialize();

    for (int i = 0; i < listeners.length; i++) {
      controller.addListener(listeners[i]);
    }

    await controller.setVolume(_isMuted ? 0.0 : _currentVolume);

    if (_activeAudioDevice != null && _activeAudioDevice != 'default') {
      controller.setProperty("audio.device", _activeAudioDevice!);
    }
    if (_audioSyncDelayMs != 0) {
      final sec = _audioSyncDelayMs / 1000.0;
      controller.setProperty("audio-delay", "$sec");
    }

    try {
      final audioTracks = controller.getActiveAudioTracks();
      if (audioTracks == null || audioTracks.isEmpty) {
        controller.setAudioTracks([0]);
      }
    } catch (_) {}

    await controller.play();
  }

  @override
  bool? get isBuffering => controller.value.isBuffering;

  @override
  bool? get isInitialized => controller.value.isInitialized;

  @override
  bool? get isPlaying => controller.value.isPlaying;

  @override
  Future<void> pause() {
    return controller.pause();
  }

  @override
  Future<void> play() {
    return controller.play();
  }

  @override
  int? get position => controller.value.position.inMilliseconds;

  @override
  void addListener(VoidCallback cb) {
    controller.addListener(cb);
    listeners.add(cb);
  }

  @override
  void removeListener(VoidCallback cb) {
    controller.removeListener(cb);
    listeners.remove(cb);
  }

  @override
  Future<void> seekTo(Duration duration) {
    return controller.seekTo(duration);
  }

  @override
  void setAudioTrack(AudioStream aud) async {
    controller.selectAudioTrack(aud.groupId);
  }

  @override
  void setFit(BoxFit fit) {
    throw UnimplementedError("Fit mode is managed via AspectRatio");
  }

  @override
  Future<void> setPip(bool value) {
    throw Exception("PiP isn't supported natively on desktop.");
  }

  @override
  void setQuality(QualityStream qs) async {
    await initiateVideo(qs.url, headers: controller.httpHeaders, offline: false);
  }

  @override
  Future<void> setSpeed(double speed) {
    return controller.setPlaybackSpeed(speed);
  }

  @override
  Future<void> setVolume(double volume) {
    _currentVolume = volume;
    if (!_isMuted) {
      return controller.setVolume(volume);
    }
    return Future.value();
  }

  @override
  double? get volume => _isMuted ? 0.0 : controller.value.volume;
}
