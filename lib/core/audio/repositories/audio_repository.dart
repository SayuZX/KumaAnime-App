import 'package:kumaanime/core/audio/models/audio_device.dart';

abstract class AudioRepository {
  Future<List<AudioDevice>> getAudioDevices();
  Stream<List<AudioDevice>> watchAudioDevices();
  Future<AudioDevice?> getDefaultAudioDevice();
  void dispose();
}
