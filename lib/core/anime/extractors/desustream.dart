import 'dart:convert';

import 'package:kumaanime/core/anime/extractors/type.dart';
import 'package:kumaanime/core/anime/providers/types.dart';
import 'package:http/http.dart';

class DesuStream extends AnimeExtractor {
  static const _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36',
  };

  @override
  Future<List<VideoStream>> extract(String streamUrl, {String? label, String? quality}) async {
    if (streamUrl.isEmpty) {
      throw Exception("ERROR: INVALID STREAM LINK");
    }

    final serverName = label ?? "desustream";
    final host = Uri.parse(streamUrl).host;
    final body = await _fetch(streamUrl, referer: "https://$host/");

    final bloggerUrl = RegExp(r'https://www\.blogger\.com/video\.g\?token=[^"'
            "'"
            r' <]+')
        .firstMatch(body)
        ?.group(0);
    if (bloggerUrl != null) {
      final bloggerStreams = await _extractBlogger(bloggerUrl, serverName);
      if (bloggerStreams.isNotEmpty) return bloggerStreams;
    }

    final direct = _findDirectLink(body);
    if (direct != null) {
      return [
        VideoStream(
          server: serverName,
          url: direct,
          quality: quality ?? "multi-quality",
          backup: false,
          customHeaders: {"Referer": streamUrl},
        ),
      ];
    }

    throw Exception("Couldnt get any $serverName streams");
  }

  Future<List<VideoStream>> _extractBlogger(String bloggerUrl, String serverName) async {
    final body = await _fetch(bloggerUrl, referer: "https://www.blogger.com/");
    final config = RegExp(r'VIDEO_CONFIG\s*=\s*(\{.*?\})\s*<').firstMatch(body)?.group(1) ??
        RegExp(r'"streams":\s*(\[.*?\])').firstMatch(body)?.group(0);
    if (config == null) return [];

    final normalized = config.startsWith('"streams"') ? '{$config}' : config;
    try {
      final decoded = json.decode(normalized) as Map<String, dynamic>;
      final streams = (decoded['streams'] as List?) ?? [];
      final result = <VideoStream>[];
      for (final stream in streams) {
        final url = stream['play_url']?.toString();
        if (url == null || url.isEmpty) continue;
        result.add(VideoStream(
          server: serverName,
          url: url,
          quality: _formatToQuality(stream['format_id']),
          backup: false,
          customHeaders: {"Referer": "https://www.blogger.com/"},
        ));
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  String _formatToQuality(dynamic formatId) {
    switch (formatId?.toString()) {
      case '18':
        return '360p';
      case '22':
        return '720p';
      case '37':
        return '1080p';
      default:
        return 'default';
    }
  }

  String? _findDirectLink(String body) {
    final patterns = [
      RegExp(r'''file\s*:\s*['"](https?://[^'"]+)['"]'''),
      RegExp(r'''sources\s*:\s*\[\s*\{[^}]*['"]?(https?://[^'"]+\.(?:m3u8|mp4)[^'"]*)['"]?'''),
      RegExp(r'''src\s*:\s*['"](https?://[^'"]+\.(?:m3u8|mp4)[^'"]*)['"]'''),
      RegExp(r'''<source[^>]+src=["'](https?://[^"']+)["']'''),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) return match.group(1)!.trim();
    }
    return null;
  }

  Future<String> _fetch(String url, {required String referer}) async {
    final res = await get(Uri.parse(url), headers: {..._headers, 'Referer': referer}).timeout(const Duration(seconds: 20));
    return res.body;
  }
}
