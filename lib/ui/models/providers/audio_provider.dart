import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/audio/models/audio_device.dart';
import 'package:kumaanime/core/audio/repositories/audio_repository.dart';
import 'package:kumaanime/core/audio/repositories/windows_audio_repository.dart';
import 'package:kumaanime/core/data/settings.dart';
import 'package:kumaanime/core/data/types.dart';
import 'package:kumaanime/ui/models/playerControllers/fvp.dart';

class AudioProvider extends ChangeNotifier {
  final AudioRepository _repository;
  StreamSubscription<List<AudioDevice>>? _sub;

  List<AudioDevice> _devices = [];
  AudioDevice? _selectedDevice;
  bool _isAutoFollowDefault = true;
  double _volume = 1.0;
  bool _isMuted = false;
  int _audioSyncDelayMs = 0;
  FvpWrapper? _activePlayer;

  List<AudioDevice> get devices => _devices;
  AudioDevice? get selectedDevice => _selectedDevice;
  bool get isAutoFollowDefault => _isAutoFollowDefault;
  double get volume => _volume;
  bool get isMuted => _isMuted;
  int get audioSyncDelayMs => _audioSyncDelayMs;

  AudioProvider({AudioRepository? repository})
      : _repository = repository ?? WindowsAudioRepository() {
    _loadSettings();
    _initDeviceListener();
  }

  void attachPlayer(FvpWrapper player) {
    _activePlayer = player;
    _applyAudioToPlayer();
  }

  void detachPlayer() {
    _activePlayer = null;
  }

  void _loadSettings() {
    final s = currentUserSettings;
    _volume = s?.audioVolume ?? 1.0;
    _isMuted = s?.isMuted ?? false;
    _audioSyncDelayMs = s?.audioSyncDelay ?? 0;
    _isAutoFollowDefault = s?.autoFollowDefaultAudioDevice ?? true;
  }

  void _initDeviceListener() {
    refreshDevices();
    _sub = _repository.watchAudioDevices().listen((deviceList) {
      _devices = deviceList;
      _updateDeviceSelection();
      notifyListeners();
    });
  }

  Future<void> refreshDevices() async {
    _devices = await _repository.getAudioDevices();
    _updateDeviceSelection();
    notifyListeners();
  }

  void _updateDeviceSelection() {
    if (_devices.isEmpty) return;

    if (_isAutoFollowDefault) {
      _selectedDevice = _devices.firstWhere(
        (d) => d.isDefault,
        orElse: () => _devices.first,
      );
    } else {
      final savedId = currentUserSettings?.audioOutputDevice;
      if (savedId != null && savedId.isNotEmpty) {
        _selectedDevice = _devices.firstWhere(
          (d) => d.id == savedId || d.name == savedId,
          orElse: () => _devices.first,
        );
      } else {
        _selectedDevice = _devices.firstWhere(
          (d) => d.isDefault,
          orElse: () => _devices.first,
        );
      }
    }
    _applyAudioToPlayer();
  }

  void selectDevice(AudioDevice device) async {
    _selectedDevice = device;
    _isAutoFollowDefault = device.isDefault;

    final s = SettingsModal(
      audioOutputDevice: device.id,
      autoFollowDefaultAudioDevice: _isAutoFollowDefault,
    );
    await Settings().writeSettings(s);
    currentUserSettings = await Settings().getSettings();

    _applyAudioToPlayer();
    notifyListeners();
  }

  void setAutoFollowDefault(bool follow) async {
    _isAutoFollowDefault = follow;
    if (follow && _devices.isNotEmpty) {
      _selectedDevice = _devices.firstWhere(
        (d) => d.isDefault,
        orElse: () => _devices.first,
      );
    }

    final s = SettingsModal(autoFollowDefaultAudioDevice: follow);
    await Settings().writeSettings(s);
    currentUserSettings = await Settings().getSettings();

    _applyAudioToPlayer();
    notifyListeners();
  }

  void setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
    _isMuted = _volume == 0;

    final s = SettingsModal(audioVolume: _volume, isMuted: _isMuted);
    await Settings().writeSettings(s);
    currentUserSettings = await Settings().getSettings();

    _applyAudioToPlayer();
    notifyListeners();
  }

  void toggleMute() async {
    _isMuted = !_isMuted;

    final s = SettingsModal(isMuted: _isMuted);
    await Settings().writeSettings(s);
    currentUserSettings = await Settings().getSettings();

    _applyAudioToPlayer();
    notifyListeners();
  }

  void setAudioSyncDelay(int delayMs) async {
    _audioSyncDelayMs = delayMs;

    final s = SettingsModal(audioSyncDelay: delayMs);
    await Settings().writeSettings(s);
    currentUserSettings = await Settings().getSettings();

    _applyAudioToPlayer();
    notifyListeners();
  }

  void resetToDefault() async {
    _isAutoFollowDefault = true;
    _volume = 1.0;
    _isMuted = false;
    _audioSyncDelayMs = 0;

    if (_devices.isNotEmpty) {
      _selectedDevice = _devices.firstWhere((d) => d.isDefault, orElse: () => _devices.first);
    }

    final s = SettingsModal(
      audioOutputDevice: 'default',
      autoFollowDefaultAudioDevice: true,
      audioVolume: 1.0,
      isMuted: false,
      audioSyncDelay: 0,
    );
    await Settings().writeSettings(s);
    currentUserSettings = await Settings().getSettings();

    _applyAudioToPlayer();
    notifyListeners();
  }

  void _applyAudioToPlayer() {
    if (_activePlayer == null) return;
    try {
      _activePlayer!.setVolume(_volume);
      _activePlayer!.setMute(_isMuted);
      _activePlayer!.setAudioSyncDelay(_audioSyncDelayMs);

      if (_selectedDevice != null) {
        if (_selectedDevice!.isDefault || _selectedDevice!.id == 'default') {
          _activePlayer!.setAudioDevice('default');
        } else {
          _activePlayer!.setAudioDevice(_selectedDevice!.name);
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _sub?.cancel();
    _repository.dispose();
    super.dispose();
  }
}
