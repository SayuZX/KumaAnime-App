import "package:kumaanime/core/news/types.dart";
import "package:http/http.dart";
import "package:html/parser.dart" as html;

class AnimeNews implements NewsService {
  final String _baseUrl = 'https://animenewsnetwork.com';

  final String _cdnUrl = 'https://cdn.animenewsnetwork.com';

  @override
  String get credit => "Anime News Network";

  @override
  Future<NewsDetailData> getDetailedNews(String url) async {
    final res = await fetch(url);
    final document = html.parse(res);
    final pageTitle = document
        .querySelector("div#page-title > h1#page_header")
        ?.text
        .replaceAll(RegExp(r'News'), '')
        .replaceAll(r'\n| {2,}', '')
        .trim();
    final postedOn = document.querySelector('div#page-title > small')?.text.trim();
    final captions = document.querySelectorAll('figcaption');
    for (final caption in captions) {
      caption.remove();
    }
    final details = document.querySelector('div.text-zone.easyread-width > div.KonaBody > div.meat');
    final imagePath = details?.querySelector('figure > img')?.attributes['data-src'];
    final image = imagePath != null ? _cdnUrl + imagePath : null;
    final List<String> texts = [];
    details?.children.forEach((element) {
      texts.add(element.text.trim());
    });
    return NewsDetailData(
      title: pageTitle ?? '',
      image: image,
      body: texts.join(),
      postedOn: postedOn,
      url: url,
    );
  }

  @override
  Future<List<NewsItem>> getNewses() async {
    final url = _baseUrl + '/news';
    final res = await fetch(url);
    final document = html.parse(res);
    final List<NewsItem> newses = [];
    document.querySelectorAll('.herald.box.news.t-news').forEach((element) {
      final src = element.querySelector('.thumbnail')?.attributes['data-src'];
      final image = src != null ? _cdnUrl + src : null;
      final wrapDiv = element.querySelector('.wrap > div');
      final titleElement = wrapDiv?.querySelector('h3')?.children[0];
      final ref = titleElement?.attributes['href'] != null ? url + (titleElement?.attributes['href'] ?? '') : null;
      final title = titleElement?.text.trim();
      final dateAndTime = wrapDiv?.querySelector('time')?.attributes['datetime'];
      final dateSplit = dateAndTime?.split('T')[0].split('-');
      final date = "${dateSplit?[2] ?? null}-${dateSplit?[1] ?? null}-${dateSplit?[0] ?? null}";
      final time = dateAndTime?.split('T')[1].split(RegExp(r'\+|\-'))[0];
      final topic = wrapDiv?.querySelector('.topics > a')?.attributes['topic'];
      final snippet = wrapDiv?.querySelector('.snippet > span.full')?.text;
      if (title == null || ref == null) return;
      newses.add(NewsItem(
        image: image,
        title: title,
        url: ref,
        date: date,
        time: time ?? '',
        category: topic,
        snippet: snippet,
      ));
    });

    return newses;
  }

  Future<String> fetch(String url) async {
    final res = await get(Uri.parse(url)).timeout(const Duration(seconds: 25));
    if (res.statusCode != 200) {
      throw Exception("News source returned HTTP ${res.statusCode}");
    }
    return res.body;
  }
}
