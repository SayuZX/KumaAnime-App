import 'dart:convert';

import 'package:kumaanime/core/anime/extractors/desustream.dart';
import 'package:kumaanime/core/anime/providers/animeProvider.dart';
import 'package:kumaanime/core/anime/providers/subIndoTypes.dart';
import 'package:kumaanime/core/anime/providers/types.dart';
import 'package:kumaanime/core/app/env.dart';
import 'package:http/http.dart';

/// Provider for Indonesian-subtitled anime, backed by a self-hostable
/// wajik-anime-api instance scraping Otakudesu. Subtitles are hardsubbed.
class OtakuDesu extends AnimeProvider {
  final String baseUrl = "${KumaAnimeEnvironment.subIndoApiUrl}/otakudesu";

  @override
  String get providerName => "otakudesu";

  Future<Map<String, dynamic>> _getJson(String path) async {
    final res = await get(Uri.parse("$baseUrl$path")).timeout(const Duration(seconds: 25));
    if (res.statusCode != 200) {
      throw Exception("Sub indo API returned HTTP ${res.statusCode}");
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    if (body['statusCode'] != 200 || body['data'] == null) {
      throw Exception("Sub indo API error: ${body['statusMessage'] ?? 'unknown'}");
    }
    return body;
  }

  List<SubIndoAnime> _parseAnimeList(dynamic data) {
    return ((data?['animeList'] ?? []) as List)
        .map((e) => SubIndoAnime.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  bool _hasNextPage(Map<String, dynamic> body) {
    return body['pagination']?['hasNextPage'] ?? false;
  }

  Future<SubIndoPagedResult> getOngoing({int page = 1}) async {
    final body = await _getJson("/ongoing?page=$page");
    return SubIndoPagedResult(items: _parseAnimeList(body['data']), hasNextPage: _hasNextPage(body));
  }

  Future<SubIndoPagedResult> getCompleted({int page = 1}) async {
    final body = await _getJson("/completed?page=$page");
    return SubIndoPagedResult(items: _parseAnimeList(body['data']), hasNextPage: _hasNextPage(body));
  }

  Future<List<SubIndoGenre>> getGenres() async {
    final body = await _getJson("/genre");
    return ((body['data']?['genreList'] ?? []) as List)
        .map((e) => SubIndoGenre.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<SubIndoPagedResult> getByGenre(String genreId, {int page = 1}) async {
    final body = await _getJson("/genre/$genreId?page=$page");
    return SubIndoPagedResult(items: _parseAnimeList(body['data']), hasNextPage: _hasNextPage(body));
  }

  Future<List<SubIndoAnime>> searchAnime(String query) async {
    final body = await _getJson("/search?q=${Uri.encodeQueryComponent(query)}");
    return _parseAnimeList(body['data']);
  }

  Future<SubIndoAnimeDetail> getDetail(String animeId) async {
    final body = await _getJson("/anime/$animeId");
    return SubIndoAnimeDetail.fromMap(Map<String, dynamic>.from(body['data']));
  }

  @override
  Future<List<Map<String, String?>>> search(String query) async {
    final results = await searchAnime(query);
    return results
        .map((e) => {
              'name': e.title,
              'alias': e.animeId,
              'imageUrl': e.poster,
            })
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getAnimeEpisodeLink(String aliasId, {bool dub = false}) async {
    final detail = await getDetail(aliasId);
    return detail.episodeList.map((e) => e.toMap()).toList();
  }

  @override
  Future<void> getStreams(String episodeId, Function(List<VideoStream>, bool) update,
      {bool dub = false, String? metadata}) async {
    final body = await _getJson("/episode/$episodeId");
    final data = Map<String, dynamic>.from(body['data']);

    final futures = <Future<void>>[];

    final defaultUrl = data['defaultStreamingUrl']?.toString();
    if (defaultUrl != null && defaultUrl.isNotEmpty) {
      futures.add(_extractEmbed(defaultUrl, "Otakudesu", "default", update));
    }

    final qualityList = ((data['server']?['qualityList'] ?? []) as List);
    for (final quality in qualityList) {
      final qualityTitle = quality['title']?.toString().trim() ?? 'unknown';
      for (final server in ((quality['serverList'] ?? []) as List)) {
        futures.add(_resolveServer(Map<String, dynamic>.from(server), qualityTitle, update));
      }
    }

    await Future.wait(futures);
    update([], true);
  }

  Future<void> _resolveServer(
      Map<String, dynamic> server, String quality, Function(List<VideoStream>, bool) update) async {
    try {
      final serverId = server['serverId']?.toString();
      if (serverId == null || serverId.isEmpty) return;
      final body = await _getJson("/server/$serverId");
      final embedUrl = body['data']?['url']?.toString();
      if (embedUrl == null || embedUrl.isEmpty) return;
      await _extractEmbed(embedUrl, server['title']?.toString() ?? 'server', quality, update);
    } catch (_) {
      // Dead mirrors are common, skip silently and let the rest resolve
    }
  }

  Future<void> _extractEmbed(
      String embedUrl, String server, String quality, Function(List<VideoStream>, bool) update) async {
    try {
      final streams = await DesuStream().extract(embedUrl, label: server, quality: quality);
      update(streams, false);
    } catch (_) {
      // Extraction failure on one embed shouldn't kill the others
    }
  }

  @override
  Future<void> getDownloadSources(String episodeUrl, Function(List<VideoStream>, bool) update,
      {bool dub = false, String? metadata}) {
    throw UnimplementedError();
  }
}
