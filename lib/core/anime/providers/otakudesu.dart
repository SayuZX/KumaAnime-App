import 'dart:convert';

import 'package:kumaanime/core/anime/extractors/desustream.dart';
import 'package:kumaanime/core/anime/extractors/streamwish.dart';
import 'package:kumaanime/core/anime/providers/animeProvider.dart';
import 'package:kumaanime/core/anime/providers/subIndoTypes.dart';
import 'package:kumaanime/core/anime/providers/types.dart';
import 'package:kumaanime/core/app/env.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart';

class OtakuDesu extends AnimeProvider {
  final String baseUrl = KumaAnimeEnvironment.subIndoBaseUrl;

  static const _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36',
  };

  @override
  String get providerName => "otakudesu";

  Future<Document> _getDoc(String path) async {
    final res = await get(Uri.parse("$baseUrl$path"), headers: _headers).timeout(const Duration(seconds: 25));
    if (res.statusCode != 200) {
      throw Exception("Otakudesu returned HTTP ${res.statusCode}");
    }
    return html.parse(res.body);
  }

  String _slug(String? href, String type) {
    if (href == null) return '';
    final match = RegExp('/$type/([^/]+)').firstMatch(href);
    return match?.group(1) ?? '';
  }

  String? _episodeCount(String? raw) {
    if (raw == null) return null;
    final match = RegExp(r'(\d+)').firstMatch(raw);
    return match?.group(1);
  }

  bool _hasNextPage(Document doc) {
    return doc.querySelector('.pagenavix a.next, .pagination a.next, a.next.page-numbers') != null;
  }

  List<SubIndoAnime> _parseVenzList(Document doc) {
    final items = <SubIndoAnime>[];
    for (final li in doc.querySelectorAll('.venz ul li')) {
      final anchor = li.querySelector('.thumb a');
      final animeId = _slug(anchor?.attributes['href'], 'anime');
      final title = li.querySelector('.jdlflm')?.text.trim() ?? '';
      final poster = li.querySelector('.thumbz img')?.attributes['src'];
      if (animeId.isEmpty || title.isEmpty) continue;
      items.add(SubIndoAnime(
        animeId: animeId,
        title: title,
        poster: poster ?? '',
        episodes: _episodeCount(li.querySelector('.epz')?.text),
        releaseDay: li.querySelector('.newnime')?.text.trim(),
      ));
    }
    return items;
  }

  List<SubIndoAnime> _parseColList(Document doc) {
    final items = <SubIndoAnime>[];
    for (final col in doc.querySelectorAll('.col-anime-con')) {
      final anchor = col.querySelector('.col-anime-title a');
      final animeId = _slug(anchor?.attributes['href'], 'anime');
      final title = anchor?.text.trim() ?? '';
      final poster = col.querySelector('.col-anime-cover img')?.attributes['src'];
      if (animeId.isEmpty || title.isEmpty) continue;
      items.add(SubIndoAnime(
        animeId: animeId,
        title: title,
        poster: poster ?? '',
        episodes: _episodeCount(col.querySelector('.col-anime-eps')?.text),
        score: col.querySelector('.col-anime-rating')?.text.trim(),
      ));
    }
    return items;
  }

  Future<SubIndoPagedResult> getOngoing({int page = 1}) async {
    final path = page <= 1 ? "/ongoing-anime/" : "/ongoing-anime/page/$page/";
    final doc = await _getDoc(path);
    return SubIndoPagedResult(items: _parseVenzList(doc), hasNextPage: _hasNextPage(doc));
  }

  Future<SubIndoPagedResult> getCompleted({int page = 1}) async {
    final path = page <= 1 ? "/complete-anime/" : "/complete-anime/page/$page/";
    final doc = await _getDoc(path);
    return SubIndoPagedResult(items: _parseVenzList(doc), hasNextPage: _hasNextPage(doc));
  }

  Future<List<SubIndoGenre>> getGenres() async {
    final doc = await _getDoc("/genre-list/");
    final genres = <SubIndoGenre>[];
    for (final anchor in doc.querySelectorAll('.genres li a')) {
      final genreId = _slug(anchor.attributes['href'], 'genres');
      final title = anchor.text.trim();
      if (genreId.isEmpty || title.isEmpty) continue;
      genres.add(SubIndoGenre(title: title, genreId: genreId));
    }
    return genres;
  }

  Future<SubIndoPagedResult> getByGenre(String genreId, {int page = 1}) async {
    final path = page <= 1 ? "/genres/$genreId/" : "/genres/$genreId/page/$page/";
    final doc = await _getDoc(path);
    return SubIndoPagedResult(items: _parseColList(doc), hasNextPage: _hasNextPage(doc));
  }

  Future<List<SubIndoAnime>> searchAnime(String query) async {
    final doc = await _getDoc("/?s=${Uri.encodeQueryComponent(query)}&post_type=anime");
    final items = <SubIndoAnime>[];
    for (final li in doc.querySelectorAll('.chivsrc li')) {
      final anchor = li.querySelector('h2 a');
      final animeId = _slug(anchor?.attributes['href'], 'anime');
      final title = anchor?.text.trim() ?? '';
      final poster = li.querySelector('img')?.attributes['src'];
      if (animeId.isEmpty || title.isEmpty) continue;
      final genres = li
          .querySelectorAll('.set a')
          .map((a) => SubIndoGenre(title: a.text.trim(), genreId: _slug(a.attributes['href'], 'genres')))
          .toList();
      items.add(SubIndoAnime(
        animeId: animeId,
        title: title,
        poster: poster ?? '',
        status: _infoAfter(li.querySelectorAll('.set'), 'Status'),
        score: _infoAfter(li.querySelectorAll('.set'), 'Rating'),
        genres: genres,
      ));
    }
    return items;
  }

  String? _infoAfter(List<Element> sets, String label) {
    for (final set in sets) {
      final text = set.text.trim();
      if (text.startsWith(label)) {
        return text.substring(label.length).replaceFirst(':', '').trim();
      }
    }
    return null;
  }

  Future<SubIndoAnimeDetail> getDetail(String animeId) async {
    final doc = await _getDoc("/anime/$animeId/");

    final info = <String, String>{};
    for (final p in doc.querySelectorAll('.infozingle p')) {
      final label = p.querySelector('b')?.text.trim();
      if (label == null) continue;
      info[label] = p.text.replaceFirst('$label:', '').trim();
    }

    final genres = doc
        .querySelectorAll('.infozingle p a')
        .map((a) => SubIndoGenre(title: a.text.trim(), genreId: _slug(a.attributes['href'], 'genres')))
        .toList();

    final synopsis = doc.querySelectorAll('.sinopc p').map((p) => p.text.trim()).where((t) => t.isNotEmpty).join("\n\n");

    final episodes = <EpisodeDetails>[];
    for (final anchor in doc.querySelectorAll('.episodelist ul li span a')) {
      final href = anchor.attributes['href'];
      if (href == null || !href.contains('/episode/')) continue;
      final title = anchor.text.trim();
      final number = RegExp(r'[Ee]pisode\s*(\d+)').firstMatch(title)?.group(1);
      episodes.add(EpisodeDetails(
        episodeLink: _slug(href, 'episode'),
        episodeNumber: int.tryParse(number ?? '') ?? episodes.length + 1,
        episodeTitle: title,
      ));
    }
    episodes.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));

    return SubIndoAnimeDetail(
      title: info['Judul'] ?? doc.querySelector('.jdlrx h1')?.text.trim() ?? '',
      japanese: info['Japanese'],
      score: info['Skor'],
      type: info['Tipe'],
      status: info['Status'],
      episodes: _episodeCount(info['Total Episode']),
      duration: info['Durasi'],
      aired: info['Tanggal Rilis'],
      studios: info['Studio'],
      poster: doc.querySelector('.fotoanime img')?.attributes['src'] ?? '',
      synopsis: synopsis,
      genres: genres,
      episodeList: episodes,
    );
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
    final res =
        await get(Uri.parse("$baseUrl/episode/$episodeId/"), headers: _headers).timeout(const Duration(seconds: 25));
    if (res.statusCode != 200) {
      throw Exception("Otakudesu returned HTTP ${res.statusCode}");
    }
    final body = res.body;
    final doc = html.parse(body);

    final futures = <Future<void>>[];

    final defaultEmbed = doc.querySelector('#pembed iframe, .responsive-embed-stream iframe')?.attributes['src'];
    if (defaultEmbed != null && defaultEmbed.isNotEmpty) {
      futures.add(_extractEmbed(defaultEmbed, "Otakudesu", "default", update));
    }

    final mirrorAction = RegExp(r'\{\.\.\.e,nonce:[^,]+,action:"([a-f0-9]+)"').firstMatch(body)?.group(1);
    final nonceAction = RegExp(r'data:\{action:"([a-f0-9]+)"').firstMatch(body)?.group(1);

    if (mirrorAction != null && nonceAction != null) {
      final nonce = await _getNonce(nonceAction);
      if (nonce != null) {
        for (final anchor in doc.querySelectorAll('.mirrorstream ul li a[data-content]')) {
          final content = anchor.attributes['data-content'];
          final quality = anchor.parent?.parent?.attributes['class']?.replaceAll('m', '') ?? 'unknown';
          if (content == null) continue;
          futures.add(_resolveMirror(content, nonce, mirrorAction, anchor.text.trim(), quality, update));
        }
      }
    }

    await Future.wait(futures);
    update([], true);
  }

  Future<String?> _getNonce(String action) async {
    try {
      final res = await post(
        Uri.parse("$baseUrl/wp-admin/admin-ajax.php"),
        headers: {..._headers, 'Referer': baseUrl},
        body: {'action': action},
      ).timeout(const Duration(seconds: 20));
      final data = json.decode(res.body)['data'];
      return data is String ? data : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _resolveMirror(String content, String nonce, String action, String server, String quality,
      Function(List<VideoStream>, bool) update) async {
    try {
      final decoded = json.decode(utf8.decode(base64.decode(content))) as Map<String, dynamic>;
      final res = await post(
        Uri.parse("$baseUrl/wp-admin/admin-ajax.php"),
        headers: {..._headers, 'Referer': baseUrl},
        body: {
          'id': decoded['id'].toString(),
          'i': decoded['i'].toString(),
          'q': decoded['q'].toString(),
          'nonce': nonce,
          'action': action,
        },
      ).timeout(const Duration(seconds: 20));
      final encoded = json.decode(res.body)['data'];
      if (encoded is! String) return;
      final iframeHtml = utf8.decode(base64.decode(encoded));
      final embedUrl = RegExp(r'src="([^"]+)"').firstMatch(iframeHtml)?.group(1);
      if (embedUrl == null || embedUrl.isEmpty) return;
      await _extractEmbed(embedUrl, server, quality, update);
    } catch (_) {
      // Dead mirrors are common, skip silently and let the rest resolve
    }
  }

  Future<void> _extractEmbed(
      String embedUrl, String server, String quality, Function(List<VideoStream>, bool) update) async {
    try {
      final host = Uri.parse(embedUrl).host.toLowerCase();
      List<VideoStream> streams;
      if (host.contains('vidhide') || host.contains('streamwish') || host.contains('filelions')) {
        streams = await StreamWish().extract(embedUrl, label: server);
      } else if (host.contains('desustream') || host.contains('blogger')) {
        streams = await DesuStream().extract(embedUrl, label: server, quality: quality);
      } else {
        return;
      }
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
