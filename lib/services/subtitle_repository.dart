import 'package:kumaanime/models/subtitle.dart';

abstract class SubtitleRepository {
  Future<List<SubtitleTrack>> fetchSubtitleTracks(int animeId, int episodeNumber);
}
