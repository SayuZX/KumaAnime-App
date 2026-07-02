import 'package:kumaanime/core/news/types.dart';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart';
import 'package:xml/xml.dart';

/// Indonesian anime news from KAORI Nusantara's RSS feed
class KaoriNews implements NewsService {
  final String _feedUrl = 'https://www.kaorinusantara.or.id/feed';

  static const _headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'};

  static const _months = {
    'Jan': '01',
    'Feb': '02',
    'Mar': '03',
    'Apr': '04',
    'May': '05',
    'Jun': '06',
    'Jul': '07',
    'Aug': '08',
    'Sep': '09',
    'Oct': '10',
    'Nov': '11',
    'Dec': '12',
  };

  @override
  String get credit => "KAORI Nusantara";

  @override
  Future<List<NewsItem>> getNewses() async {
    final res = await get(Uri.parse(_feedUrl), headers: _headers).timeout(const Duration(seconds: 25));
    if (res.statusCode != 200) {
      throw Exception("News feed returned HTTP ${res.statusCode}");
    }
    final document = XmlDocument.parse(res.body);
    final List<NewsItem> newses = [];
    for (final item in document.findAllElements('item')) {
      final title = item.getElement('title')?.innerText.trim() ?? '';
      final url = item.getElement('link')?.innerText.trim() ?? '';
      if (title.isEmpty || url.isEmpty) continue;
      final (date, time) = _parsePubDate(item.getElement('pubDate')?.innerText ?? '');
      final descriptionHtml = item.getElement('description')?.innerText ?? '';
      final snippet = html.parse(descriptionHtml).body?.text.trim();
      newses.add(NewsItem(
        title: title,
        url: url,
        date: date,
        time: time,
        category: item.findElements('category').firstOrNull?.innerText.trim(),
        snippet: snippet,
      ));
    }
    return newses;
  }

  (String, String) _parsePubDate(String pubDate) {
    final match = RegExp(r'(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})\s+(\d{2}:\d{2})').firstMatch(pubDate);
    if (match == null) return ('', '');
    final day = match.group(1)!.padLeft(2, '0');
    final month = _months[match.group(2)] ?? '01';
    return ('$day-$month-${match.group(3)}', match.group(4)!);
  }

  @override
  Future<NewsDetailData> getDetailedNews(String url) async {
    final res = await get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 25));
    if (res.statusCode != 200) {
      throw Exception("News page returned HTTP ${res.statusCode}");
    }
    final document = html.parse(res.body);

    final title = document.querySelector('meta[property="og:title"]')?.attributes['content'] ??
        document.querySelector('h1')?.text.trim() ??
        '';
    final image = document.querySelector('meta[property="og:image"]')?.attributes['content'];
    final postedOn = document.querySelector('meta[property="article:published_time"]')?.attributes['content'];

    // Themes vary, so probe the usual WordPress content containers
    const containerSelectors = [
      '.entry-content',
      '.td-post-content',
      'div[itemprop="articleBody"]',
      '.post-content',
      'article',
    ];
    String body = '';
    for (final selector in containerSelectors) {
      final container = document.querySelector(selector);
      if (container == null) continue;
      final paragraphs =
          container.querySelectorAll('p').map((p) => p.text.trim()).where((t) => t.isNotEmpty).toList();
      if (paragraphs.length >= 2) {
        body = paragraphs.join('\n\n');
        break;
      }
    }

    return NewsDetailData(
      title: title,
      image: image,
      body: body,
      postedOn: postedOn,
      url: url,
    );
  }
}
