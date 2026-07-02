import 'package:kumaanime/core/anime/extractors/type.dart';
import 'package:kumaanime/core/anime/providers/types.dart';
import 'package:kumaanime/core/commons/utils.dart';

class DesuStream extends AnimeExtractor {
  @override
  Future<List<VideoStream>> extract(String streamUrl, {String? label, String? quality}) async {
    if (streamUrl.isEmpty) {
      throw Exception("ERROR: INVALID STREAM LINK");
    }

    final serverName = label ?? "desustream";
    final body = await fetch(streamUrl);

    final patterns = [
      RegExp(r'''file:\s*['"](https?://[^'"]+)['"]'''),
      RegExp(r'''src:\s*['"](https?://[^'"]+\.(?:m3u8|mp4|mkv)[^'"]*)['"]'''),
      RegExp(r'''<source[^>]+src=["'](https?://[^"']+)["']'''),
      RegExp(r'''<video[^>]+src=["'](https?://[^"']+)["']'''),
    ];

    String streamLink = '';
    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        streamLink = match.group(1)!.trim();
        break;
      }
    }

    final uri = Uri.tryParse(streamLink);
    if (streamLink.isEmpty || uri == null || !uri.hasScheme) {
      throw Exception("Couldnt get any $serverName streams");
    }

    return [
      VideoStream(
        server: serverName,
        url: streamLink,
        quality: quality ?? "default",
        backup: false,
        customHeaders: {"Referer": streamUrl},
      ),
    ];
  }
}
