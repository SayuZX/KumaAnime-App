import 'package:kumaanime/core/anime/providers/types.dart';

class SubIndoGenre {
  final String title;
  final String genreId;

  SubIndoGenre({
    required this.title,
    required this.genreId,
  });

  factory SubIndoGenre.fromMap(Map<String, dynamic> map) {
    return SubIndoGenre(
      title: map['title']?.toString() ?? '',
      genreId: map['genreId']?.toString() ?? '',
    );
  }
}

class SubIndoAnime {
  final String animeId;
  final String title;
  final String poster;
  final String? episodes;
  final String? score;
  final String? status;
  final String? releaseDay;
  final String? latestReleaseDate;
  final List<SubIndoGenre> genres;

  SubIndoAnime({
    required this.animeId,
    required this.title,
    required this.poster,
    this.episodes,
    this.score,
    this.status,
    this.releaseDay,
    this.latestReleaseDate,
    this.genres = const [],
  });

  factory SubIndoAnime.fromMap(Map<String, dynamic> map) {
    return SubIndoAnime(
      animeId: map['animeId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      poster: map['poster']?.toString() ?? '',
      episodes: map['episodes']?.toString(),
      score: map['score']?.toString(),
      status: map['status']?.toString(),
      releaseDay: map['releaseDay']?.toString(),
      latestReleaseDate: (map['latestReleaseDate'] ?? map['lastReleaseDate'])?.toString(),
      genres: ((map['genreList'] ?? []) as List)
          .map((e) => SubIndoGenre.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class SubIndoAnimeDetail {
  final String title;
  final String? japanese;
  final String? score;
  final String? type;
  final String? status;
  final String? episodes;
  final String? duration;
  final String? aired;
  final String? studios;
  final String poster;
  final String synopsis;
  final List<SubIndoGenre> genres;
  final List<EpisodeDetails> episodeList;

  SubIndoAnimeDetail({
    required this.title,
    required this.poster,
    required this.synopsis,
    this.japanese,
    this.score,
    this.type,
    this.status,
    this.episodes,
    this.duration,
    this.aired,
    this.studios,
    this.genres = const [],
    this.episodeList = const [],
  });

  factory SubIndoAnimeDetail.fromMap(Map<String, dynamic> map) {
    final rawEpisodes = ((map['episodeList'] ?? []) as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    // The API lists newest episodes first, so numbers fall back to reverse order
    final episodeList = <EpisodeDetails>[];
    for (var i = 0; i < rawEpisodes.length; i++) {
      final raw = rawEpisodes[i];
      final title = raw['title']?.toString() ?? '';
      final parsedNumber = RegExp(r'[Ee]pisode\s*(\d+)').firstMatch(title)?.group(1);
      episodeList.add(EpisodeDetails(
        episodeLink: raw['episodeId']?.toString() ?? '',
        episodeNumber: int.tryParse(parsedNumber ?? '') ?? (rawEpisodes.length - i),
        episodeTitle: title,
      ));
    }
    episodeList.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));

    return SubIndoAnimeDetail(
      title: map['title']?.toString() ?? '',
      japanese: map['japanese']?.toString(),
      score: map['score']?.toString(),
      type: map['type']?.toString(),
      status: map['status']?.toString(),
      episodes: map['episodes']?.toString(),
      duration: map['duration']?.toString(),
      aired: map['aired']?.toString(),
      studios: map['studios']?.toString(),
      poster: map['poster']?.toString() ?? '',
      synopsis: ((map['synopsis']?['paragraphList'] ?? []) as List).join("\n\n"),
      genres: ((map['genreList'] ?? []) as List)
          .map((e) => SubIndoGenre.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      episodeList: episodeList,
    );
  }
}

class SubIndoPagedResult {
  final List<SubIndoAnime> items;
  final bool hasNextPage;

  SubIndoPagedResult({
    required this.items,
    required this.hasNextPage,
  });
}
