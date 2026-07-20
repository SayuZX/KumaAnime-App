import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

enum AudioDeviceType {
  defaultDevice,
  speaker,
  headset,
  bluetooth,
  hdmi,
  usb,
  virtual,
  unknown,
}

enum AudioDeviceStatus {
  defaultDevice,
  connected,
  disconnected,
}

class AudioDevice {
  final String id;
  final String name;
  final AudioDeviceType type;
  final AudioDeviceStatus status;
  final bool isDefault;

  const AudioDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    this.isDefault = false,
  });

  IconData get icon {
    switch (type) {
      case AudioDeviceType.defaultDevice:
        return HugeIcons.strokeRoundedSpeaker;
      case AudioDeviceType.headset:
        return HugeIcons.strokeRoundedHeadphones;
      case AudioDeviceType.bluetooth:
        return HugeIcons.strokeRoundedBluetooth;
      case AudioDeviceType.hdmi:
        return HugeIcons.strokeRoundedTv01;
      case AudioDeviceType.usb:
      case AudioDeviceType.virtual:
        return HugeIcons.strokeRoundedSettings02;
      case AudioDeviceType.speaker:
      case AudioDeviceType.unknown:
        return HugeIcons.strokeRoundedSpeaker;
    }
  }

  static AudioDeviceType parseType(String name, String instanceId) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains("headphone") || lowerName.contains("headset") || lowerName.contains("earphone")) {
      return AudioDeviceType.headset;
    }
    if (lowerName.contains("bluetooth") || lowerName.contains("wireless") || lowerName.contains("bt")) {
      return AudioDeviceType.bluetooth;
    }
    if (lowerName.contains("hdmi") || lowerName.contains("nvidia") || lowerName.contains("display") || lowerName.contains("tv") || lowerName.contains("monitor")) {
      return AudioDeviceType.hdmi;
    }
    if (lowerName.contains("virtual") || lowerName.contains("broadcast") || lowerName.contains("vb-audio") || lowerName.contains("cable")) {
      return AudioDeviceType.virtual;
    }
    if (lowerName.contains("usb") || lowerName.contains("dac")) {
      return AudioDeviceType.usb;
    }
    if (lowerName.contains("speaker") || lowerName.contains("realtek") || lowerName.contains("audio")) {
      return AudioDeviceType.speaker;
    }
    return AudioDeviceType.unknown;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioDevice && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
