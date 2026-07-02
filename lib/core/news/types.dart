class NewsItem {
  final String title;
  final String url;
  final String? image;
  final String date;
  final String time;
  final String? category;
  final String? snippet;

  NewsItem({
    required this.title,
    required this.url,
    required this.date,
    required this.time,
    this.image,
    this.category,
    this.snippet,
  });
}

class NewsDetailData {
  final String title;
  final String? image;
  final String body;
  final String? postedOn;
  final String url;

  NewsDetailData({
    required this.title,
    required this.body,
    required this.url,
    this.image,
    this.postedOn,
  });
}

abstract class NewsService {
  /// Name shown in the credits line of the detail page
  String get credit;

  Future<List<NewsItem>> getNewses();

  Future<NewsDetailData> getDetailedNews(String url);
}
