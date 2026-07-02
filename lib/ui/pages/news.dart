import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/ui/models/widgets/loader.dart';
import 'package:kumaanime/core/news/animenews.dart';
import 'package:kumaanime/core/news/kaoriNews.dart';
import 'package:kumaanime/core/news/types.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:kumaanime/ui/models/widgets/cards.dart';
import 'package:kumaanime/ui/pages/newsDetail.dart';
import 'package:flutter/material.dart';

class News extends StatefulWidget {
  const News({super.key});

  @override
  State<News> createState() => _NewsState();
}

class _NewsState extends State<News> {
  final Map<String, NewsService> _services = {
    'global': AnimeNews(),
    'indo': KaoriNews(),
  };

  late String _selected;
  List<NewsItem> newses = [];
  bool loaded = false;
  bool error = false;

  NewsService get _service => _services[_selected]!;

  @override
  void initState() {
    super.initState();
    _selected = (currentUserSettings?.locale ?? 'en') == 'id' ? 'indo' : 'global';
    getNewses();
  }

  Future<void> getNewses() async {
    setState(() {
      loaded = false;
      error = false;
      newses = [];
    });
    try {
      final data = await _service.getNewses();
      if (!mounted) return;
      setState(() {
        newses = data;
        loaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        error = true;
        loaded = true;
      });
    }
  }

  void _switchSource(String source) {
    if (_selected == source) return;
    _selected = source;
    getNewses();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: appTheme.textMainColor,
          ),
        ),
        backgroundColor: appTheme.backgroundColor,
        title: Text(
          loc.newsTitle,
          style: TextStyle(color: appTheme.textMainColor, fontFamily: "Poppins", fontSize: 25),
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 40,
            margin: const EdgeInsets.only(top: 5, bottom: 5),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              children: [
                _sourceChip(label: loc.newsSourceGlobal, source: 'global'),
                _sourceChip(label: loc.newsSourceIndo, source: 'indo'),
              ],
            ),
          ),
          Expanded(child: _body(loc)),
        ],
      ),
    );
  }

  Widget _sourceChip({required String label, required String source}) {
    final selected = _selected == source;
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _switchSource(source),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? appTheme.accentColor : appTheme.backgroundSubColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? appTheme.onAccent : appTheme.textMainColor,
              fontFamily: "NotoSans",
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(AppLocalizations loc) {
    if (!loaded) {
      return Center(
        child: KumaAnimeLoading(color: appTheme.accentColor, size: 40),
      );
    }

    if (error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              loc.newsLoadError,
              textAlign: TextAlign.center,
              style: TextStyle(color: appTheme.textSubColor, fontFamily: "NotoSans", fontSize: 16),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: getNewses,
              style: ElevatedButton.styleFrom(
                backgroundColor: appTheme.accentColor,
                foregroundColor: appTheme.onAccent,
              ),
              child: Text(loc.retry),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: getNewses,
      color: appTheme.accentColor,
      backgroundColor: appTheme.backgroundSubColor,
      child: ListView.builder(
        padding: MediaQuery.of(context).padding.copyWith(top: 10),
        itemCount: newses.length,
        itemBuilder: (context, index) => GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => NewsDetails(
                      url: newses[index].url,
                      service: _service,
                    )));
          },
          child: Container(
            decoration: const BoxDecoration(color: Colors.transparent),
            padding: const EdgeInsets.only(top: 5, left: 10, right: 10),
            child: Cards.NewsCard(
              newses[index].title,
              newses[index].image,
              newses[index].date,
              newses[index].time,
            ),
          ),
        ),
      ),
    );
  }
}
