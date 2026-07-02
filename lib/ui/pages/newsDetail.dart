import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/news/types.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsDetails extends StatefulWidget {
  final String url;
  final NewsService service;

  const NewsDetails({
    super.key,
    required this.url,
    required this.service,
  });

  @override
  State<NewsDetails> createState() => _NewsDetailsState();
}

class _NewsDetailsState extends State<NewsDetails> {
  NewsDetailData? news;
  bool loaded = false;
  bool error = false;

  @override
  void initState() {
    super.initState();
    getDetailedNews();
  }

  Future<void> getDetailedNews() async {
    setState(() {
      loaded = false;
      error = false;
    });
    try {
      final res = await widget.service.getDetailedNews(widget.url);
      if (!mounted) return;
      setState(() {
        news = res;
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
      body: !loaded
          ? Center(
              child: CircularProgressIndicator(color: appTheme.accentColor),
            )
          : error
              ? _errorBody(loc)
              : _content(loc),
    );
  }

  Widget _errorBody(AppLocalizations loc) {
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
            onPressed: getDetailedNews,
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

  Widget _content(AppLocalizations loc) {
    final detail = news!;
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 25, top: 25),
            child: Text(
              detail.title,
              style: TextStyle(
                color: appTheme.textMainColor,
                fontFamily: "Poppins",
                fontSize: 25,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (detail.image != null)
            Image.network(
              detail.image!,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) return child;
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: child,
                );
              },
              errorBuilder: (context, err, stackTrace) => const SizedBox.shrink(),
            ),
          if (detail.body.isNotEmpty)
            Container(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 25),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: detail.body[0],
                      style: detailStyle(true),
                    ),
                    TextSpan(
                      text: detail.body.substring(1),
                      style: detailStyle(false),
                    )
                  ],
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.only(top: 25),
            child: TextButton.icon(
              onPressed: () => launchUrl(Uri.parse(detail.url), mode: LaunchMode.externalApplication),
              icon: Icon(Icons.open_in_new_rounded, size: 18, color: appTheme.accentColor),
              label: Text(
                loc.readFullArticle,
                style: TextStyle(color: appTheme.accentColor, fontFamily: "NotoSans"),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(bottom: 50, top: 10),
            child: Text(
              "credits: ${widget.service.credit}",
              style: TextStyle(
                color: appTheme.textSubColor,
                fontFamily: 'NunitoSans',
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle detailStyle(bool bold) {
    return TextStyle(
        color: appTheme.textMainColor,
        fontFamily: 'NotoSans',
        fontSize: 18,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal);
  }
}
