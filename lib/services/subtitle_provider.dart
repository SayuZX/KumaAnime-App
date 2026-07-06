import 'package:kumaanime/models/subtitle.dart';
import 'package:kumaanime/services/subtitle_repository.dart';

class ApiSubtitleRepositoryImpl implements SubtitleRepository {
  @override
  Future<List<SubtitleTrack>> fetchSubtitleTracks(int animeId, int episodeNumber) async {
    await Future.delayed(const Duration(milliseconds: 600));

    return [
      SubtitleTrack(
        language: "Indonesia",
        url: "https://mock-subtitle-service.kumaanime.app/subtitles/$animeId/$episodeNumber/id.vtt",
        format: "vtt",
      ),
      SubtitleTrack(
        language: "Jepang",
        url: "https://mock-subtitle-service.kumaanime.app/subtitles/$animeId/$episodeNumber/ja.ass",
        format: "ass",
      ),
      SubtitleTrack(
        language: "English",
        url: "https://mock-subtitle-service.kumaanime.app/subtitles/$animeId/$episodeNumber/en.ssa",
        format: "ssa",
      ),
      SubtitleTrack(
        language: "Spanish",
        url: "https://mock-subtitle-service.kumaanime.app/subtitles/$animeId/$episodeNumber/es.srt",
        format: "srt",
      ),
    ];
  }
}
