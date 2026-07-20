import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:kumaanime/core/app/logging.dart';
import 'package:kumaanime/core/audio/models/audio_device.dart';
import 'package:kumaanime/core/audio/repositories/audio_repository.dart';

class WindowsAudioRepository implements AudioRepository {
  Timer? _poller;
  final StreamController<List<AudioDevice>> _controller = StreamController<List<AudioDevice>>.broadcast();
  List<AudioDevice> _cachedDevices = [];

  WindowsAudioRepository() {
    _initPoller();
  }

  void _initPoller() {
    if (!Platform.isWindows) return;
    // Initial fetch
    getAudioDevices().then((devices) {
      if (!_controller.isClosed) {
        _controller.add(devices);
      }
    });

    // Periodic poll for hot-swap audio device changes every 3 seconds
    _poller = Timer.periodic(const Duration(seconds: 3), (_) async {
      final devices = await getAudioDevices();
      if (!_controller.isClosed) {
        _controller.add(devices);
      }
    });
  }

  @override
  Future<List<AudioDevice>> getAudioDevices() async {
    if (!Platform.isWindows) {
      return [
        const AudioDevice(
          id: 'default',
          name: 'System Default Audio',
          type: AudioDeviceType.defaultDevice,
          status: AudioDeviceStatus.defaultDevice,
          isDefault: true,
        ),
      ];
    }

    try {
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        '''
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
        \$devices = Get-PnpDevice -Class AudioEndpoint -ErrorAction SilentlyContinue | Select-Object FriendlyName, InstanceId, Status
        \$results = @()
        foreach (\$d in \$devices) {
          if (\$d.InstanceId -like "*0.0.0.00000000*") {
            \$results += [PSCustomObject]@{
              Name = \$d.FriendlyName
              Id = \$d.InstanceId
              Status = \$d.Status
            }
          }
        }
        \$results | ConvertTo-Json
        '''
      ]).timeout(const Duration(seconds: 4));

      if (result.exitCode == 0 && (result.stdout as String).trim().isNotEmpty) {
        final String rawJson = result.stdout as String;
        final dynamic decoded = json.decode(rawJson);
        final List<dynamic> list = decoded is List ? decoded : [decoded];

        final List<AudioDevice> parsed = [];

        // Always include System Default entry
        parsed.add(
          const AudioDevice(
            id: 'default',
            name: 'Default Speaker (Windows)',
            type: AudioDeviceType.defaultDevice,
            status: AudioDeviceStatus.defaultDevice,
            isDefault: true,
          ),
        );

        for (final item in list) {
          if (item == null) continue;
          final name = (item['Name'] ?? 'Unknown Audio Device').toString();
          final id = (item['Id'] ?? name).toString();
          final statusStr = (item['Status'] ?? 'OK').toString();

          final type = AudioDevice.parseType(name, id);
          final status = statusStr == 'OK'
              ? AudioDeviceStatus.connected
              : AudioDeviceStatus.disconnected;

          parsed.add(
            AudioDevice(
              id: id,
              name: name,
              type: type,
              status: status,
              isDefault: false,
            ),
          );
        }

        _cachedDevices = parsed;
        return parsed;
      }
    } catch (e) {
      Logs.app.log("[AUDIO_REPO] Failed to enumerate Windows audio devices: $e");
    }

    if (_cachedDevices.isNotEmpty) {
      return _cachedDevices;
    }

    return [
      const AudioDevice(
        id: 'default',
        name: 'Default Speaker (Windows)',
        type: AudioDeviceType.defaultDevice,
        status: AudioDeviceStatus.defaultDevice,
        isDefault: true,
      ),
    ];
  }

  @override
  Stream<List<AudioDevice>> watchAudioDevices() {
    return _controller.stream;
  }

  @override
  Future<AudioDevice?> getDefaultAudioDevice() async {
    final devices = await getAudioDevices();
    return devices.firstWhere(
      (d) => d.isDefault,
      orElse: () => devices.first,
    );
  }

  @override
  void dispose() {
    _poller?.cancel();
    _controller.close();
  }
}
