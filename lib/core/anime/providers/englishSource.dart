import 'package:kumaanime/core/anime/providers/animeLangSource.dart';
import 'package:kumaanime/core/anime/providers/subIndoTypes.dart';
import 'package:kumaanime/core/anime/providers/types.dart';
import 'package:kumaanime/core/commons/enums.dart';
import 'package:kumaanime/core/database/anilist/anilist.dart';
import 'package:kumaanime/core/database/anilist/types.dart';
import 'package:kumaanime/ui/models/sources.dart';

/// English anime source backed by AniList for browsing and the inbuilt
/// SourceManager providers for stream resolution.
class EnglishSource implements AnimeLangSource {
  final Anilist _anilist = Anilist();

  static const List<String> _genres = [
    'Action',
    'Adventure',
    'Comedy',
    'Drama',
    'Ecchi',
    'Fantasy',
    'Horror',
    'Mahou Shoujo',
    'Mecha',
    'Music',
    'Mystery',
    'Psychological',
    'Romance',
    'Sci-Fi',
    'Slice of Life',
    'Sports',
    'Supernatural',
    'Thriller',
  ];

  String _stripHtml(String? input) {
    if (input == null) return '';
    return input
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&mldr;', '...')
        .replaceAll('&amp;', '&')
        .trim();
  }

  String _pickTitle(Map<String, dynamic> title) {
    return (title['english'] ?? title['romaji'] ?? title['native'] ?? '').toString();
  }

  SubIndoAnime _mapMedia(Map<String, dynamic> media) {
    final title = Map<String, dynamic>.from(media['title'] ?? {});
    final score = media['averageScore'];
    final episodes = media['episodes'];
    return SubIndoAnime(
      animeId: media['id'].toString(),
      title: _pickTitle(title),
      poster: (media['coverImage']?['large'] ?? '').toString(),
      score: score is int ? (score / 10).toString() : null,
      status: media['status']?.toString(),
      episodes: episodes != null ? episodes.toString() : null,
    );
  }

  Future<SubIndoPagedResult> _browse(String filters, int page) async {
    final query = '''
      {
        Page(page: $page, perPage: 24) {
          pageInfo { hasNextPage }
          media(type: ANIME, $filters, isAdult: false) {
            id
            title { english romaji native }
            coverImage { large }
            averageScore
            episodes
            status
            genres
          }
        }
      }
    ''';

    final data = await _anilist.fetchQuery(query, null);
    final page0 = data?['Page'];
    if (page0 == null) return SubIndoPagedResult(items: [], hasNextPage: false);

    final List<dynamic> media = page0['media'] ?? [];
    final bool hasNextPage = page0['pageInfo']?['hasNextPage'] == true;

    final items = media.map((e) => _mapMedia(Map<String, dynamic>.from(e))).toList();
    return SubIndoPagedResult(items: items, hasNextPage: hasNextPage);
  }

  @override
  Future<SubIndoPagedResult> getOngoing({int page = 1}) {
    return _browse('status: RELEASING, sort: POPULARITY_DESC', page);
  }

  @override
  Future<SubIndoPagedResult> getCompleted({int page = 1}) {
    return _browse('status: FINISHED, sort: POPULARITY_DESC', page);
  }

  @override
  Future<SubIndoPagedResult> getByGenre(String genreId, {int page = 1}) {
    return _browse('genre: "$genreId", sort: POPULARITY_DESC', page);
  }

  @override
  Future<List<SubIndoAnime>> searchAnime(String query) async {
    final gquery = '''
      {
        Page(page: 1, perPage: 24) {
          media(type: ANIME, search: "$query", isAdult: false, sort: SEARCH_MATCH) {
            id
            title { english romaji native }
            coverImage { large }
            averageScore
            episodes
            status
            genres
          }
        }
      }
    ''';

    final data = await _anilist.fetchQuery(gquery, RequestType.media);
    if (data == null) return [];
    final List<dynamic> media = data;
    return media.map((e) => _mapMedia(Map<String, dynamic>.from(e))).toList();
  }

  @override
  Future<List<SubIndoGenre>> getGenres() async {
    return _genres.map((e) => SubIndoGenre(title: e, genreId: e)).toList();
  }

  @override
  Future<SubIndoAnimeDetail> getDetail(String animeId) async {
    final id = int.parse(animeId);
    final AnilistInfo info = await _anilist.getAnimeInfo(id);

    final String primaryTitle = (info.title['english'] ?? info.title['romaji'] ?? info.title['native'] ?? '').toString();

    final int episodeCount = info.episodes ?? 12;
    final List<EpisodeDetails> episodeList = List.generate(episodeCount, (index) {
      final epNum = index + 1;
      return EpisodeDetails(
        episodeLink: '$animeId::$epNum::$primaryTitle',
        episodeNumber: epNum,
        episodeTitle: 'Episode $epNum',
      );
    });

    final genres = info.genres
        .map((e) => e.toString())
        .map((e) => SubIndoGenre(title: e, genreId: e))
        .toList();

    return SubIndoAnimeDetail(
      title: primaryTitle,
      japanese: info.title['native'],
      score: info.rating?.toString(),
      type: info.type,
      status: info.status,
      episodes: info.episodes?.toString(),
      duration: info.duration,
      aired: info.aired['start'],
      studios: info.studios.whereType<String>().join(', '),
      poster: info.cover,
      synopsis: _stripHtml(info.synopsis),
      genres: genres,
      episodeList: episodeList,
    );
  }

  @override
  Future<void> getStreams(String episodeId, Function(List<VideoStream>, bool) update,
      {bool dub = false, String? metadata}) async {
    final parts = episodeId.split('::');
    final int epNum = parts.length > 1 ? (int.tryParse(parts[1]) ?? 1) : 1;
    final String title = parts.length > 2 ? parts[2] : '';

    final manager = SourceManager.instance;
    final Set<String> seenUrls = {};
    final List<VideoStream> aggregated = [];

    for (final source in manager.inbuiltSources) {
      if (source.identifier.contains('otakudesu')) continue;
      try {
        final streams = await _resolveProviderStreams(source.identifier, title, epNum, dub)
            .timeout(const Duration(seconds: 12));
        if (streams.isEmpty) continue;

        var added = false;
        for (final stream in streams) {
          if (seenUrls.add(stream.url)) {
            aggregated.add(stream);
            added = true;
          }
        }
        if (added) update(List<VideoStream>.from(aggregated), false);
      } catch (_) {
        continue;
      }
    }

    update([], true);
  }

  Future<List<VideoStream>> _resolveProviderStreams(String sourceId, String title, int epNum, bool dub) async {
    final manager = SourceManager.instance;
    manager.useInbuiltProviders = true;

    if (title.trim().isEmpty) return [];

    final results = await manager.searchInSource(sourceId, title);
    if (results.isEmpty) return [];

    final exact = results.where((e) => (e['name'] ?? '').toLowerCase() == title.toLowerCase()).toList();
    final match = exact.isNotEmpty ? exact.first : results.first;
    final alias = match['alias'];
    if (alias == null) return [];

    final episodes = await manager.getAnimeEpisodes(sourceId, alias, dub: dub);
    if (episodes.isEmpty) return [];

    final ep = episodes.firstWhere(
      (e) => e.episodeNumber == epNum,
      orElse: () => (epNum - 1) < episodes.length ? episodes[epNum - 1] : episodes.first,
    );

    final collected = <VideoStream>[];
    await manager.getStreams(sourceId, ep.episodeLink, dub: dub, metadata: ep.metadata, (list, finished) {
      collected.addAll(list);
    });
    return collected;
  }

  @override
  String get playerSourceId => 'gojo_inbuilt';

  @override
  String get watchedNamespace => 'en';
}
