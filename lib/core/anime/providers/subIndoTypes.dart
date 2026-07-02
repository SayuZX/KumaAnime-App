import 'package:kumaanime/core/anime/providers/types.dart';

class SubIndoGenre {
  final String title;
  final String genreId;

  SubIndoGenre({
    required this.title,
    required this.genreId,
  });
}

class SubIndoAnime {
  final String animeId;
  final String title;
  final String poster;
  final String? episodes;
  final String? score;
  final String? status;
  final String? releaseDay;
  final List<SubIndoGenre> genres;

  SubIndoAnime({
    required this.animeId,
    required this.title,
    required this.poster,
    this.episodes,
    this.score,
    this.status,
    this.releaseDay,
    this.genres = const [],
  });
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

  bool get isMovie => (type ?? '').toLowerCase().contains('movie');

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
}

class SubIndoPagedResult {
  final List<SubIndoAnime> items;
  final bool hasNextPage;

  SubIndoPagedResult({
    required this.items,
    required this.hasNextPage,
  });
}
