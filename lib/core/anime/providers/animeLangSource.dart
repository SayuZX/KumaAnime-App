import 'package:kumaanime/core/anime/providers/subIndoTypes.dart';
import 'package:kumaanime/core/anime/providers/types.dart';

/// Shared surface for a browsable, language-specific anime source used by the
/// INDONESIA / ENGLISH pages. Both the Indonesian scraper and the English
/// AniList-backed source implement this so the pages stay reusable.
abstract class AnimeLangSource {
  Future<SubIndoPagedResult> getOngoing({int page = 1});

  Future<SubIndoPagedResult> getCompleted({int page = 1});

  Future<List<SubIndoGenre>> getGenres();

  Future<SubIndoPagedResult> getByGenre(String genreId, {int page = 1});

  Future<List<SubIndoAnime>> searchAnime(String query);

  Future<SubIndoAnimeDetail> getDetail(String animeId);

  Future<void> getStreams(String episodeId, Function(List<VideoStream>, bool) update,
      {bool dub = false, String? metadata});

  /// Provider identifier handed to the player for preload/fallback.
  String get playerSourceId;

  /// Namespace prefix so watched-history from different languages never collide.
  String get watchedNamespace;
}
